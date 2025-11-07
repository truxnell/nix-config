{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "satisfactory";
  category = "services";
  description = "Satisfactory Dedicated Server";
  image = "docker.io/wolveix/satisfactory-server:latest";
  user = "1000"; # string
  group = "1000"; # string
  gamePort = 7777; # int - Game port (UDP)
  queryPort = 8888; # int - Query port (UDP)
  appFolder = "/var/lib/${app}";
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
      default = false;
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
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };
    openFirewall = mkOption {
      type = lib.types.bool;
      description = "Open firewall for remote players";
      default = true;
    };
    serverName = mkOption {
      type = lib.types.str;
      description = "Server name displayed in game browser";
      default = "NixOS Satisfactory Server";
    };
    maxPlayers = mkOption {
      type = lib.types.int;
      description = "Maximum number of players";
      default = 10;
    };
    adminPassword = mkOption {
      type = lib.types.str;
      description = "Admin password for server management";
      default = "admin123";
    };
    autoPause = mkOption {
      type = lib.types.bool;
      description = "Auto-pause when no players";
      default = true;
    };
    autoSaveInterval = mkOption {
      type = lib.types.int;
      description = "Auto-save interval in seconds";
      default = 300;
    };
  };

  config = mkIf cfg.enable {

    ## Secrets - uncomment if you want to use sops for passwords
    # sops.secrets."${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "podman-${app}.service" ];
    # };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
      "d ${appFolder}/config 0750 ${user} ${group} -"
      "d ${appFolder}/gamefiles 0750 ${user} ${group} -"
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${appFolder}/config:/config:rw"
        "${appFolder}/gamefiles:/gamefiles:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        # Server Configuration
        MAXPLAYERS = builtins.toString cfg.maxPlayers;
        PGID = group;
        PUID = user;
        STEAMBETA = "false";
        # Game Settings

      };
      # environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      ports = [
        "${builtins.toString gamePort}:${builtins.toString gamePort}/udp" # Game port
        "${builtins.toString gamePort}:${builtins.toString gamePort}/tcp" # Game port
        "${builtins.toString queryPort}:${builtins.toString queryPort}/tcp" # Query port
      ];
      extraOptions = [
        "--pull=always"
      ];
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "udp://${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString gamePort}";
        interval = "2m";
        conditions = [
          "[CONNECTED] == true"
          "[RESPONSE_TIME] < 2000"
        ];
      }
    ];

    ### firewall config
    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [
        gamePort # 7777 - Game traffic
      ];
      # Optional: Allow TCP port 8080 for web interface if exposed
      allowedTCPPorts = [
        gamePort
        queryPort
      ];
    };

    ### backups
    warnings = [
      (mkIf (
        !cfg.backup && config.mySystem.purpose != "Development"
      ) "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

  };
}
