{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "sonarr";
  image = "ghcr.io/onedr0p/sonarr:4.0.4@sha256:b487a9894af0db414484e8cbbbb4aaf3eabe3b18675081d700c19cdd60151ed6";
  user = "568"; #string
  group = "568"; #string
  port = 8989; #int
  cfg = config.mySystem.services.${app};
  appFolder = "containers/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
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
      dependsOn = [ "prowlarr" ];
      environment = {
        TZ = "${config.time.timeZone}";
        PUSHOVER_DEBUG = "false";
        PUSHOVER_APP_URL = "${app}.${config.mySystem.domain}";
        SONARR__INSTANCE_NAME = "Radarr";
        SONARR__APPLICATION_URL = "https://${app}.${config.mySystem.domain}";
        SONARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Sonarr = {
          icon = "${app}.png";
          href = "https://${app}.${config.mySystem.domain}";
          ping = "https://${app}.${config.mySystem.domain}";
          description = "TV show management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
            key = "{{HOMEPAGE_VAR_SONARR__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        excludePaths = [ "Backups" ];
        paths = [ appFolder ];
      };


  };
}
