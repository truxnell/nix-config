{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "readarr";
  image = "ghcr.io/onedr0p/readarr-nightly:0.3.23.2500";
  user = "568"; #string
  group = "568"; #string
  port = 8787; #int
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
        TZ = "${config.time.timeZone}";
        READARR__INSTANCE_NAME = "Lidarr";
        READARR__APPLICATION_URL = "https://${app}.${config.networking.domain}";
        READARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
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

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Readar = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Book management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "http://${app}:${toString port}";
            key = "{{HOMEPAGE_VAR_READARR__API_KEY}}";
          };
        };
      }
    ];
  };
}
