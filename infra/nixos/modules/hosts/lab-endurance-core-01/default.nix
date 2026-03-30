{ self, inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    self.nixosModules.base
    self.nixosModules.vm.proxmox
    self.nixosModules.users.nick
    self.nixosModules.disk.btrfs
    self.nixosModules.k3s.server
  ];

  networking.hostName = "lab-endurance-core-01";
}
