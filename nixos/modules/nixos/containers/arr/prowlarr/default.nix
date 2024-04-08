{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "prowlarr";
  image = "ghcr.io/onedr0p/prowlarr:1.15.0.4361@sha256:73e30e7c9eddd7aca3de4208e702d6293862bb5c49d7a8547cc1b9e3c35dcb86";
  user = "568"; #string
  group = "568"; #string
  port = 9696; #int
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
        PROWLARR__INSTANCE_NAME = "Prowlarr";
        PROWLARR__APPLICATION_URL = "https://${app}.${config.networking.domain}";
        PROWLARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.middlewares" = "local-only@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "${toString port}";

      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Prowlarr = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Content locator";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "http://${app}:${toString port}";
            key = "{{HOMEPAGE_VAR_PROWLARR__API_KEY}}";
          };
        };
      }
    ];
  };
}
