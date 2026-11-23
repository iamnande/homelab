# roci disk configuration
#
# one unencrypted EFI system partition (ESP).
# one LUKS-encrypted partition containing the usual btrfs shenanigans.
# 
# root fs access is gated by fido2 hardware auth via yubikey.
# 
# three-tier key redundancy:
# - primary (yubikey 5C nfc), stored in personal vault nightly
# - secondary (yubikey 5C nfc), kept in personal storage vault alongside
# physical recovery material
# - off-site backup (yubikey 5c nfc), kept in backup storage vault
#
# the LUKS recovery material is stored in both the digital and personal storage
# vaults.
#
# sasa ke, baratna?
let
  btrfsOpts = [ "compress=zstd:3" "noatime" "ssd" "discard=async" "space_cache=v2" ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_2TB_S7M4NS0X225945V";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            # yeah, passphrase me up boii (passphrase for initial & recovery).
            # yubikey on the daily.
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = { mountpoint = "/"; mountOptions = btrfsOpts; };
                "@home" = { mountpoint = "/home"; mountOptions = btrfsOpts; };
                "@nix" = { mountpoint = "/nix"; mountOptions = btrfsOpts; };
                "@log" = { mountpoint = "/var/log"; mountOptions = btrfsOpts; };
                "@snapshots" = { mountpoint = "/.snapshots"; mountOptions = btrfsOpts; };
                "@games" = { mountpoint = "/games"; mountOptions = btrfsOpts; };
              };
            };
          };
        };
      };
    };
  };
}
