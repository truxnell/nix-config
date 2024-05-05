{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "backrest";
  image = "garethgeorge/backrest:v0.17.2@sha256:8517210483be734ef89587e085e8860e071d6a6871cd773aa790f263346cbfb8";
  user = "568"; #string
  group = "568"; #string
  port = 9898; #int
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
      "d ${appFolder}/config 0750 ${user} ${group} -"
      "d ${appFolder}/data 0750 ${user} ${group} -"
      "d ${appFolder}/cache 0750 ${user} ${group} -"
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        BACKREST_PORT = "9898";
        BACKREST_DATA = "/data";
        BACKREST_CONFIG = "/config/config.json";
        XDG_CACHE_HOME = "/cache";
      };
      volumes = [
        "${appFolder}/nixos/config:/config:rw"
        "${appFolder}/nixos/data:/data:rw"
        "${appFolder}/nixos/cache:/cache:rw"
        "${config.mySystem.nasFolder}/backup/nixos/nixos:/repos:rw"
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


    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        Backrest = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Local restic backup browser";
          container = "${app}";
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "infrastructure";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

  };
}
