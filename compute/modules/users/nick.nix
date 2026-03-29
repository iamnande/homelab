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
    stow
    zellij
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # dotfiles flake — expands as stow components migrate to home-manager
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

    # clone and stow remaining dotfiles components not yet migrated to home-manager
    systemd.user.services.dotfiles-setup = {
      Unit.Description = "clone and install dotfiles";
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = "PATH=${pkgs.git}/bin:${pkgs.gnumake}/bin:${pkgs.stow}/bin:${pkgs.bash}/bin:/run/current-system/sw/bin";
        ExecStart = "${pkgs.writeShellScript "dotfiles-setup" ''
          if [ ! -d "$HOME/dotfiles" ]; then
            git clone https://github.com/iamnande/dotfiles.git "$HOME/dotfiles"
            cd "$HOME/dotfiles"
            make helix && make zellij && make claude
          fi
        ''}";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
