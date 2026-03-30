{ pkgs, ... }: {

  # boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;

  # network
  networking.networkmanager.enable = true;

  # locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # packages
  nixpkgs.config.allowUnfree = true;
  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    btop
    curl
    fd
    git
    gnumake
    helix
    htop
    jq
    lsof
    fastfetch
    fish
    nh
    nix-tree
    ripgrep
    tree
    unzip
    wget
  ];

  # programs
  programs.fish.enable = true;

  # security
  security.pam.sshAgentAuth.enable = true;

  # services
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.qemuGuest.enable = true;

  # swap
  zramSwap.enable = true;

  # nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];
  system.stateVersion = "25.11";
}
