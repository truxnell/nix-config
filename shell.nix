# Shell for bootstrapping flake-enabled nix and home-manager
{ pkgs ? let
    # If pkgs is not defined, instantiate nixpkgs from locked commit
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
    system = builtins.currentSystem;
    overlays = [ ]; # Explicit blank overlay to avoid interference


  in
  import nixpkgs { inherit system overlays; }
, ...
}:
let
  # setup the ssssnaaake
  my-python = pkgs.python311;
  python-with-my-packages = my-python.withPackages
    (p: with p; [
      mkdocs-material
      mkdocs-minify
      pygments
    ]);
in
pkgs.mkShell {
  # Enable experimental features without having to specify the argument
  NIX_CONFIG = "experimental-features = nix-command flakes";

  buildInputs = [
    python-with-my-packages
  ];
  shellHook = ''
    PYTHONPATH=${python-with-my-packages}/${python-with-my-packages.sitePackages}
  '';

  nativeBuildInputs = with pkgs; [
    nix
    home-manager
    git
    nil
    nixpkgs-fmt
    go-task
    sops
    pre-commit
    gitleaks
    mkdocs
    mqttui

  ];
}
