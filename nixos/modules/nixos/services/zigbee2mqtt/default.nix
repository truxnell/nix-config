{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.zigbee2mqtt;
  persistentFolder = "${config.mySystem.persistentFolder}/nixos/services/${app}/";
  app = "zigbee2mqtt";
  user = app;
  group = app;
  appFolder = "services/${app}";
  port = 8080;
in
{
  options.mySystem.services.zigbee2mqtt = {
    enable = mkEnableOption "zigbee2mqtt";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
  };


  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    sops.secrets."services/mosquitto/mq/plainPassword.yaml" = {
      sopsFile = ../mosquitto/secrets.sops.yaml;
      owner = config.users.users.zigbee2mqtt.name;
      inherit (config.users.users.zigbee2mqtt) group;
      restartUnits = [ "${app}.service" ];
    };

    services.zigbee2mqtt = {
      enable = true;
      dataDir = persistentFolder;
      settings = {
        advanced.log_level = "debug";
        homeassistant = true;
        permit_join = false;
        include_device_information = true;
        frontend =
          {
            port = port;
            url = "https://${app}.${config.networking.domain}";
          };
        client_id = "z2m";
        serial = {
          port = "tcp://10.8.30.110:6638";
        };
        mqtt = {
          server = "mqtt://mqtt.trux.dev:1883";
          user = "mq";
          password = "!${config.sops.secrets."services/mosquitto/mq/plainPassword.yaml".path} password";
        };

      };
    };

    users.users.truxnell.extraGroups = [ app ];

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1${builtins.toString port}";
      };
    };


    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";
          description = "Zigbee bridge to MQTT";
          container = "${app}";
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "services";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app;
        user = builtins.toString user;
        paths = [ "services/${app}" ];
        appFolder = app;
        inherit persistentFolder;
      };


  };
}
