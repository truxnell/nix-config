# shell.nix  (kept for direnv speed)
{ pkgs ?  # let the flake supply pkgs
    (builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}
}:

let
  python-with-packages = pkgs.python311.withPackages (ps: with ps; [
    mkdocs-material
    mkdocs-minify
    pygments
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python-with-packages
    nix
    git
    nil
    nixpkgs-fmt
    just
    sops
    pre-commit
    gitleaks
    mkdocs
    mqttui
    deploy-rs
    cachix
    omnix
    go-task
  ];
}
