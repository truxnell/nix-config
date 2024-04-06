{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "sonarr";
  image = "ghcr.io/onedr0p/sonarr@sha256:04d8e198752b67df3f95c46144b507f437e7669f0088e7d2bbedf0e762606655";
  user = "568"; #string
  group = "568"; #string
  port = 8989; #int
  cfg = config.mySystem.services.sonarr;
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";
in
{
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 568 568 -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    sops.secrets."services/${app}/env" = {

      # configure secret for forwarding rules
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      group = config.users.users.kah.group;
      restartUnits = [ "podman-${app}.service" ];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      environment = {
        UMASK = "002";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "/mnt/nas/natflix/series:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.middlewares" = "local-only@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "${toString port}";

      };
    };

    mySystem.services.homepage.media-services = [
      {
        Sonarr = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "TV series management";
          server = "${config.networking.hostName}}";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "http://${app}:8989";
            key = "{{HOMEPAGE_VAR_SONARR_APIKEY}}";
          };
        };
      }
    ];
  };
}
