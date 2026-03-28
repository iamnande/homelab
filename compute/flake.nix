{
  description = "mhq homelab compute";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {

    mhq = {
      base       = ./modules/base.nix;
      dev        = ./modules/dev.nix;
      vm.proxmox = ./modules/vm/proxmox.nix;
      users.nick = ./modules/users/nick.nix;
      disk.btrfs = ./modules/disk/btrfs.nix;
    };

    nixosConfigurations = {

      devbox-nick = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/hosts/devbox-nick/default.nix ];
      };

    };

  };
}
