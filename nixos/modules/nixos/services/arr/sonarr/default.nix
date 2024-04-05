{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.sonarr;
in
{
  options.mySystem.services.sonarr.enable = mkEnableOption "Sonarr";

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers.sonarr = {
      image = "ghcr.io/onedr0p/sonarr@sha256:04d8e198752b67df3f95c46144b507f437e7669f0088e7d2bbedf0e762606655";
      environment = {
        UMASK = "002";
      };
      volumes = [
        "${config.mySystem.persistentFolder}/nixos/traefik/:/config:rw"
        "/mnt/nas/natflix/series:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };
  };
}
