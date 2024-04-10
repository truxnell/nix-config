{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "lidarr";
  image = "ghcr.io/onedr0p/lidarr:2.1.7";
  user = "568"; #string
  group = "568"; #string
  port = 8686; #int
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
      dependsOn = [ "prowlarr" ];
      environment = {
        PUSHOVER_DEBUG = "false";
        PUSHOVER_APP_URL = "${app}.${config.networking.domain}";
        LIDARR__INSTANCE_NAME = "Lidarr";
        LIDARR__APPLICATION_URL = "https://${app}.${config.networking.domain}";
        LIDARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Lidarr = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Music management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.networking.domain}";
            key = "{{HOMEPAGE_VAR_LIDARR__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "arr";
      url = "https://${app}.${config.networking.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }];

  };
}
