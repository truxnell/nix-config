{
  lib,
  config,
  ...
}:
with lib;
let
  app = "minecraft-bedrock";
  category = "services";
  description = "Minecraft Bedrock Server";
  instance = "CordiWorld";
  image = "docker.io/itzg/minecraft-bedrock-server:latest";
  user = "568"; # string
  group = "568"; # string
  port = 19132; # int
  cfg = config.mySystem.services.${app}.${instance};
  appFolder = "/var/lib/${app}/${instance}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.services.${app}.${instance} = {
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
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };

  };

  config = mkIf cfg.enable {

    ## Secrets
    # sops.secrets."${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "${app}.service" ];
    # };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              inherit user;
              inherit group;
              mode = "750";
            }
          ];
        };

    virtualisation.oci-containers.containers."${app}-${instance}" = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${appFolder}:/data:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        SERVER_NAME = "Natflix Servers";
        EULA = "TRUE";
        GAMEMODE = "creative";
        DIFFICULTY = "normal";
        FORCE_GAMEMODE = "false";
        TICK_DISTANCE = "12";
        VIEW_DISTANCE = "64";
        LEVEL_NAME = instance;
        TEXTUREPACK_REQUIRED = "false";
        WHITE_LIST = "false";
        ALLOW_CHEATS = "true";
      };
      # environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      ports = [ "${builtins.toString port}:${builtins.toString port}/UDP" ]; # expose port
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = "${app}-${instance}";
        group = "${category}";
        url = "udp://${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString port}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[RESPONSE_TIME] < 1000"
        ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

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

    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };

  };
}
