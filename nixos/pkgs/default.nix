{ pkgs, ... }:

{
  podman-containers = pkgs.callPackage ./podman-containers.nix { };
}
