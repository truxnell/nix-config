{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "ecowitt2mqtt";
  category = "containers";
  description = "Weather station to MQTT";
  image = "ghcr.io/bachya/ecowitt2mqtt:latest@sha256:2fd4793364117794923d38affda9ebf20d7b6b29a8c11dbe54981c21874b656c";
  user = "1000"; # string
  group = "1000"; # string
  port = 8080; # int
  # appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backupLocal = mkOption {
      type = lib.types.bool;
      description = "Enable local backups";
      default = true;
    };
    backupRemote = mkOption {
      type = lib.types.bool;
      description = "Enable remote backups";
      default = true;
    };

  };

  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      # owner = user;
      # inherit group;
      restartUnits = [ "podman-${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${persistentFolder}/ 0750 ${user} ${group} -"
    # ];

    ## service
    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit
        app
        image
        user
        group
        ;
      env = {
        ECOWITT2MQTT_MQTT_BROKER = "mqtt.trux.dev";
        ECOWITT2MQTT_MQTT_PORT = "1883";
        ECOWITT2MQTT_MQTT_TOPIC = "ecowitt2mqtt/pws";
        ECOWITT2MQTT_PORT = "8080";
        ECOWITT2MQTT_HASS_DISCOVERY = "true";
        ECOWITT2MQTT_OUTPUT_UNIT_SYSTEM = "metric"; # Come on guys nobody want to use freedum units"
      };
      envFiles = [ config.sops.secrets."${category}/${app}/env".path ];
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "http://${url}/data/report"; # check https & the reporting URL for 405 'method not allowed's
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 405"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      # I dont need/want ssl for this one, weather station expets http
      # useACMEHost = config.networking.domain;
      # forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        proxyWebsockets = true;
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    # warnings = [
    #   (mkIf (!cfg.backupLocal && config.mySystem.purpose != "Development")
    #     "WARNING: Local backups for ${app} are disabled!")
    #   (mkIf (!cfg.backupRemote && config.mySystem.purpose != "Development")
    #     "WARNING: Remote backups for ${app} are disabled!")
    # ];

    # services.restic.backups = mkIf cfg.backups config.lib.mySystem.mkRestic
    #   {
    #     inherit app user;
    #     paths = [ appFolder ];
    #     inherit appFolder;
    #     local = cfg.backupLocal;
    #     remote = cfg.backupRemote;
    #   };

  };
}
