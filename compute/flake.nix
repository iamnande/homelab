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
    nixosConfigurations = {

      # initial vm - manually provisioned, uuid-based disk config
      ifrit = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ ./modules/hosts/ifrit/default.nix ];
      };

      # k3s worker nodes added in a future session
      # worker-01 = ...

    };
  };
}
