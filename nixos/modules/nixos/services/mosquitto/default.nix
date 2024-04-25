{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.mosquitto;
  persistentFolder = "${config.mySystem.persistentFolder}/nixos/services/mosquitto/";
  app = "mosquitto";
  user = app;
  group = app;
in
{
  options.mySystem.services.mosquitto.enable = mkEnableOption "mosquitto MQTT";

  config = mkIf cfg.enable {

    sops.secrets."services/mosquitto/mq/hashedPassword" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "mosquitto";
      group = "mosquitto";
      restartUnits = [ "${app}.service" ];
    };

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];


    services.mosquitto = {
      enable = true;
      # persistance for convienience on restarts
      # but not backed up, there is no data
      # that requires keeping in MQTT
      dataDir = persistentFolder;
      settings = {
        persistence_location = "${persistentFolder}";
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
    users.users.truxnell.extraGroups = [ "mosquitto" ];
    networking.firewall.allowedTCPPorts = [ 1883 ];

  };
}
