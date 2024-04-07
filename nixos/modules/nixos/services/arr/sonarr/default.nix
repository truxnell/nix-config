{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "sonarr";
  image = "ghcr.io/onedr0p/sonarr:4.0.2@sha256:42ba5af9b0ea20f4db4622991e0f1657be02c6e8747872c652fdac193c097b25";
  user = "568"; #string
  group = "568"; #string
  port = 8989; #int
  cfg = config.mySystem.services.${app};
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";
  containerPersistentFolder = "/config";
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
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    sops.secrets."services/${app}/env" = {

      # configure secret for forwarding rules
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
      restartUnits = [ "podman-${app}.service" ];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        PUSHOVER_DEBUG = "false";
        PUSHOVER_APP_URL = "${app}.${config.networking.domain}";
        SONARR__INSTANCE_NAME = "Radarr";
        SONARR__APPLICATION_URL = "https://${app}.${config.networking.domain}";
        SONARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:${containerPersistentFolder}:rw"
        "/mnt/nas/natflix:/media:rw"
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
          description = "TV show management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "http://${app}:${toString port}";
            key = "{{HOMEPAGE_VAR_SONARR__API_KEY}}";
          };
        };
      }
    ];
  };
}
