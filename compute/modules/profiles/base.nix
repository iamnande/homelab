{ pkgs, ... }: {

  # boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # network
  networking.networkmanager.enable = true;

  # locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # user
  users.users.nick = {
    isNormalUser = true;
    description = "nick";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  # packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    btop
    curl
    fd
    fish
    fishPlugins.tide
    git
    gnumake
    helix
    htop
    jq
    lsof
    fastfetch
    nh
    nix-tree
    ripgrep
    stow
    tree
    unzip
    wget
    zellij
  ];

  # programs
  programs.fish.enable = true;

  # services
  services.openssh.enable = true;

  # nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
