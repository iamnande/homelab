{
  description = "mhq homelab compute";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {

    nixosModules = {
      base        = ./modules/profiles/base.nix;
      vmHardware  = ./modules/profiles/vm-hardware.nix;
      dev         = ./modules/profiles/dev.nix;
      userNick    = ./modules/profiles/users/nick.nix;
      diskVmStandard = ./modules/disk/vm-standard.nix;
    };

    nixosConfigurations = {

      ifrit = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/hosts/ifrit/default.nix ];
      };

    };

  };
}
