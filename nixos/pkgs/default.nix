{ pkgs, ... }:

{
  podman-containers = pkgs.callPackage ./cockpit-podman.nix { };
  # grafana-dashboards = pkgs.callPackage ./grafana-dashboards { };
}
