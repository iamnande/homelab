{ ... }: {
  # ifrit-specific disk mounts — uuid-based from manual proxmox installation
  # new nodes use disko (modules/disk/vm-standard.nix) instead of this pattern

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/622f548c-313f-4b4d-b3b0-295550c44a71";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/622f548c-313f-4b4d-b3b0-295550c44a71";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F8E5-4025";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [];
}
