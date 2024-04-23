{
  description = "My nixos homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
};
outputs ={
    self
    , nixpkgs
    , sops-nix
    , home-manager
    , nix-vscode-extensions
, ...
} @ inputs:

let
    inherit (self) outputs;
    forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    ];

in
{
devShells.default = pkgs.mkShell {
        packages = [
        pkgs.flyctl
        ];
    };
};