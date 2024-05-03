{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.mosquitto;
  # persistentFolder = "${config.mySystem.persistentFolder}/nixos/services/mosquitto/";
  app = "mosquitto";
  user = app;
  group = app;
  appFolder = config.services.mosquitto.dataDir;
in
{
  options.mySystem.services.mosquitto.enable = mkEnableOption "mosquitto MQTT";

  config = mkIf cfg.enable {

    sops.secrets."services/mosquitto/mq/hashedPassword" = {
      sopsFile = ./secrets.sops.yaml;
      owner = app;
      group = app;
      restartUnits = [ "${app}.service" ];
    };


    services.mosquitto = {
      enable = true;
      # persistance for convienience on restarts
      # but not backed up, there is no data
      # that requires keeping in MQTT
      settings = {
        persistence_location = appFolder;
        max_keepalive = 300;
      };

      listeners = [
        {
          users.mq = {
            acl = [
              "readwrite #"
            ];
            hashedPasswordFile = config.sops.secrets."services/mosquitto/mq/hashedPassword".path;
          };
        }
      ];
    };

     environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; user = user; group = group; mode = "750"; }];
    };

    users.users.truxnell.extraGroups = [ "mosquitto" ];
    networking.firewall.allowedTCPPorts = [ 1883 ];

  };
}
