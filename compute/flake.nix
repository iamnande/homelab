{
  description = "mhq homelab compute";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      # TODO: update to github:iamnande/dotfiles after dotfiles#7 merges
      url = "github:iamnande/dotfiles/feat/4_home-manager-flake-scaffold";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }@inputs: {

    nixosModules = {
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

      devbox-validation = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs self; };
        modules = [ ./modules/hosts/devbox-validation/default.nix ];
      };

    };

  };
}
