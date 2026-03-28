{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [

    # lsps - helix picks these up from PATH automatically
    nil                       # nix
    bash-language-server      # shell scripts
    gopls                     # go
    rust-analyzer             # rust
    typescript-language-server # typescript / javascript

    # formatters helix delegates to
    nixfmt                    # nix
    nodePackages.prettier      # ts/js/css/html/json
    rustfmt                   # rust

    # dev tooling
    devenv                    # per-project shells (language runtimes live here)
    gh                        # github cli
    tokei                     # code stats

  ];
}
