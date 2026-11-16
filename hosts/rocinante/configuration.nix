{ config, pkgs, ... }:

let
  user = "iamnande";
in
{
  networking.hostName = "rocinante";
  system.stateVersion = "26.05";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # boot sequence:
  # 1. systemd-boot picks the kernel
  # 2. systemd initrd unlocks luks
  # 3. fido2-device=auto tries the yubikey first
  # 4. then falls back to the passphrase
  # fail. you stole fizzy lifting drink. good day, sir! (*sad penguin noises*)
  # success. we need guns, lots of guns.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = [ "fido2-device=auto" ];
  boot.kernelParams = [ "zswap.enabled=0" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryMax = 4 * 1024 * 1024 * 1024;
  };

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # gpu: rtx 4070 super on the open kernel modules
  #
  # my purchase led to jensen's downfall. muahahahaha.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  # network: vlan-30 (lab)
  #
  # wired dhcp via systemd-networkd over trunk port 7, mhq-lab, on mhq-switch.
  # mhq-lab is tagged with vlan-30, blocking other vlans. mhq-lab carries the
  # mhq-lab-qos policy, experimentation pays for faster netflixing later.
  #
  # please be kind, rewind.
  networking.useNetworkd = true;
  systemd.network.enable = true;
  systemd.network.networks."20-wired" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };
  services.resolved = {
    enable = true;
    settings.Resolve = {
      LLMNR = "no";
      MulticastDNS = "no";
    };
  };

  # usb dongle, for the love of the game (sony xm6s) - as needed
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # a: give me the key.
  # b: what key?
  # a: that key.
  # b: oh, you mean this key.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AuthenticationMethods = "publickey";
    };
  };

  # cypress, long beach - what's good
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.${user} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "gamemode" ];
    shell = pkgs.fish;
  };

  # tty1 login once per boot.
  # hyprlock is the login into the rest of hyprland.
  # lock when not present. pull the key when leaving the station.
  services.getty.autologinUser = user;
  services.getty.autologinOnce = true;

  # these are my games. there are many like them, but these ones are mine.
  systemd.tmpfiles.rules = [ "d /games 0755 ${user} users -" ];

  # desktop
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  programs.hyprlock.enable = true;
  programs.fish.enable = true;
  programs.firefox.enable = true;
  programs.thunar.enable = true;
  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  systemd.packages = [ pkgs.hyprpolkitagent ];
  systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];

  # fido2 via yubis for luks and ssh
  services.pcscd.enable = true;
  services.udev.packages = [ pkgs.libfido2 pkgs.yubikey-personalization ];

  # another yacht for ol' man gabe
  programs.steam = {
    enable = true;
    protontricks.enable = true;
  };
  programs.gamemode.enable = true;
  systemd.user.services.protonplus = {
    description = "ProtonPlus";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.protonplus}/bin/protonplus update all";
    };
  };
  systemd.user.timers.protonplus = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1h";
    };
  };

  # containers are like, so cool
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  # give my bum right eye (and hyperactive brain) a bit of a break
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.open-dyslexic
  ];

  # TODO: reorganize?
  environment.systemPackages = with pkgs; [
    # tools
    bat btop difftastic eza fastfetch fd fzf glow htop jq less lychee
    ripgrep stow tree vim wget
    # system
    btrfs-progs efibootmgr smartmontools
    # dev
    # TODO: move to volta?
    buf cargo-deny cargo-nextest gcc gnumake go go-tools golangci-lint
    gopls helix lazygit marksman mdbook mdbook-mermaid mise nodejs_22
    pnpm rustup shellcheck
    # git(hub)
    gh git
    # k8s and friends
    docker-buildx docker-compose kubernetes-helm k9s kubectl kubectx lego
    # k but like, how cute of a name is "wofi" - right?
    ghostty grim hypridle hyprpaper libnotify mako pavucontrol playerctl
    slurp waybar wl-clipboard wofi xdg-utils zellij
    gnome-themes-extra libsForQt5.qtwayland kdePackages.qtwayland
    # i've got nunchuck skills
    mangohud protonplus vulkan-tools
    # keepers of keys and grounds at mhq
    bitwarden-cli bitwarden-desktop libfido2 yubikey-manager yubioath-flutter
  ];
}
