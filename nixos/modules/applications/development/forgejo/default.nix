{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "forgejo";
  category = "services";
  description = "Git forge service";
  port = 3000; # int
  sshPort = 2222; # int
  appFolder = "/var/lib/${app}";
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

    users.users.truxnell.extraGroups = [ "forgejo" ];

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
              user = "forgejo";
              group = "forgejo";
              mode = "750";
            }
          ];
        };

    ## service
    services.forgejo = {
      enable = true;
      repositoryRoot = "/zfs/forgejo";
      # SQLite is the default database, no configuration needed
      settings = {
        server = {
          DOMAIN = "${url}";
          ROOT_URL = "https://${url}/";
          HTTP_PORT = port;
          LANDING_PAGE = "explore";
          START_SSH_SERVER = true;
          SSH_PORT = sshPort;  # Non-privileged port avoids permission issues 【0】
          SSH_LISTEN_HOST = "0.0.0.0";
          SSH_DOMAIN = "daedalus";  # Match your server hostname
        };
        service = {
          DISABLE_REGISTRATION = true;
        };
      };
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 512m;
        '';
      };
    };

    ### firewall config

    networking.firewall = {
      allowedTCPPorts = [ sshPort ];
    };

    ### backups
    warnings = [
      (mkIf (
        !cfg.backup && config.mySystem.purpose != "Development"
      ) "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        app = app;
        user = "forgejo";
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };

  };
}
