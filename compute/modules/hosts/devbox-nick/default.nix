{ self, inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    self.mhq.base
    self.mhq.vm.proxmox
    self.mhq.dev
    self.mhq.users.nick
    self.mhq.disk.btrfs
  ];

  networking.hostName = "devbox-nick";
}
