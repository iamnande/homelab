{ pkgs, inputs, ... }: {
  environment.systemPackages = with pkgs; [

    # lsps
    nil
    bash-language-server
    gopls
    rust-analyzer
    typescript-language-server
    terraform-ls
    helm-ls
    yaml-language-server

    # language runtimes
    go
    rustc
    cargo
    clippy
    bun

    # language tools
    cargo-nextest
    golangci-lint
    bazelisk

    # formatters
    nixfmt
    rustfmt
    biome

    # infra
    opentofu
    tflint
    helm
    kubectl
    kubie
    k9s

    # dev tools
    jujutsu
    gh
    difftastic
    just
    xh

    # ai tools
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default

  ];
}
