{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "radarr";
  image = "ghcr.io/onedr0p/radarr:5.3.6.8612@sha256:4dcf3bb47fb83ca2fc8cfb7a35b3130aabf51e5042a68915e4182ebed203e1bf";
  user = "568"; #string
  group = "568"; #string
  port = 7878; #int
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
        RADARR__INSTANCE_NAME = "Radarr";
        RADARR__APPLICATION_URL = "https://${app}.${config.networking.domain}";
        RADARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "/mnt/nas/natflix/series:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        port = port;
      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Radarr = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Movie management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "http://${app}:${toString port}";
            key = "{{HOMEPAGE_VAR_RADARR__API_KEY}}";
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
