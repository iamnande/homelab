{ ... }: {

  services.k3s = {
    enable = true;
    role   = "server";
    # flannel CNI: default, no config needed
    # local-path storage: default, no config needed
  };

  # api server access (kubectl from devbox-nick / mac)
  networking.firewall.allowedTCPPorts = [ 6443 ];

}
