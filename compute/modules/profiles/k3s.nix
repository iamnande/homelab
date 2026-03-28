{ ... }: {
  # k3s agent - joins an existing cluster
  #
  # prerequisites before deploying:
  #   - set networking.hostName in the host's default.nix
  #   - populate /etc/k3s/token on the node (or via sops-nix - tbd)
  #   - set the correct serverAddr for your k3s server
  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://172.16.30.10:6443"; # TODO: k3s server ip
    tokenFile = "/etc/k3s/token";             # TODO: manage via sops-nix
  };

  # open firewall ports required by k3s agents
  networking.firewall = {
    allowedTCPPorts = [ 10250 ];
    allowedUDPPorts = [ 8472 ]; # flannel vxlan
  };
}
