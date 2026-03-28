{ ... }: {
  imports = [
    ../../profiles/base.nix
    ../../profiles/vm-hardware.nix
    ../../profiles/dev.nix
    ./hardware.nix
  ];

  networking.hostName = "ifrit";
}
