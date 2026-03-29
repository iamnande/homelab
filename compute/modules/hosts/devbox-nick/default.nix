{ self, inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    self.nixosModules.base
    self.nixosModules.vm.proxmox
    self.nixosModules.dev
    self.nixosModules.users.nick
    self.nixosModules.disk.btrfs
  ];

  networking.hostName = "devbox-nick";
}
