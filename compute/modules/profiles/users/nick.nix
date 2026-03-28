{ pkgs, ... }: {
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
    fishPlugins.tide
    stow
    zellij
  ];
}
