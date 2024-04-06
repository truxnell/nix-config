{ lib
, config
, pkgs
, ...
}:
with lib;
let
  image = "ghcr.io/onedr0p/sonarr@sha256:04d8e198752b67df3f95c46144b507f437e7669f0088e7d2bbedf0e762606655";
  port = 8989;
  cfg = config.mySystem.services.sonarr;
  persistentFolder = "${config.mySystem.persistentFolder}/sonarr";
in
{
  options.mySystem.services.sonarr.enable = mkEnableOption "Sonarr";

  config = mkIf cfg.enable {
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 568 568 -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.sonarr = {
      image = "${image}";
      user = "568:568";
      environment = {
        UMASK = "002";
      };
      volumes = [
        "${persistentFolder}:/config:rw"
        "/mnt/nas/natflix/series:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.sonarr.entrypoints" = "websecure";
        "traefik.http.routers.sonarr.middlewares" = "local-only@file";
        "traefik.http.services.sonarr.loadbalancer.server.port" = "${toString port}";
      };
    };
  };
}
