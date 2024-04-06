{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "homepage";
  image = "ghcr.io/gethomepage/homepage:v0.8.10";
  user = "568"; #string
  group = "568"; #string
  port = 3000; #int
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";

  cfg = config.mySystem.services.homepage;
in
{
  options.mySystem.services.homepage.enable = mkEnableOption "Homepage dashboard";

  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        UMASK = "002";
        PUID = "${user}";
        PGID = "${group}";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.middlewares" = "local-only@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "${toString port}";
      };
      # mount socket for service discovery.
      volumes = [
        "${persistentFolder}:/app/config:rw"
        "/var/run/podman/podman.sock:/var/run/docker.sock:ro" # TODO abstract out podman/docker socket
      ];

    };
  };
}
