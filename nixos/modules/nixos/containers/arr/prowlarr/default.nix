{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "prowlarr";
  image = "ghcr.io/onedr0p/prowlarr:1.16.2.4435@sha256:3d3d5702d40824da9ece02f465dbf221dfa726846e9212bc3fe89af5562e6e9e";
  user = "568"; #string
  group = "568"; #string
  port = 9696; #int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
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
      "d ${appFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
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
        PUSHOVER_APP_URL = "${app}.${config.mySystem.domain}";
        PROWLARR__INSTANCE_NAME = "Prowlarr";
        PROWLARR__APPLICATION_URL = "https://${app}.${config.mySystem.domain}";
        PROWLARR__LOG_LEVEL = "info";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${appFolder}:/config:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        Prowlarr = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Content locator";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
            key = "{{HOMEPAGE_VAR_PROWLARR__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        excludePaths = [ "Backups" ];
        paths = [ appFolder ];
        inherit appFolder;
      };

  };
}
