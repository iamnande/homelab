{ pkgs, inputs, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICoS4wfDQv3PLZYHJw668tS9zhvH73g3EgThK31wBjU0"
    ];
  };

  environment.systemPackages = with pkgs; [
    zellij
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.sharedModules = [ inputs.dotfiles.homeManagerModules.nick ];

  home-manager.users.nick = { pkgs, ... }: {
    home.stateVersion = "25.11";

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
          forwardAgent = true;
          serverAliveInterval = 180;
        };
        "172.16.*.*" = {
          extraOptions.StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };
}
