{ self, inputs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko
    self.nixosModules.base
    self.nixosModules.vmHardware
    self.nixosModules.dev
    self.nixosModules.userNick
    self.nixosModules.diskVmStandard
  ];

  networking.hostName = "devbox-nick";
}
