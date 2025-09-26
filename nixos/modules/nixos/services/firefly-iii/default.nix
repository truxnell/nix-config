{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "firefly-iii";
  category = "services";
  description = "Financial tracking";
  user = app; # string
  group = "nginx"; # string #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  commonConf = {
    APP_ENV = "production";
    APP_URL = "https://${url}";
    # TRUSTED_PROXIES = toString config.host.networking.containerHostIP;
    LOG_CHANNEL = "stdout";
    LOG_LEVEL = "notice";
    TZ = config.time.timeZone;
  };
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
    sops.secrets."${category}/${app}/app_key" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      group = group;
      restartUnits = [ "${app}.service" ];
    };

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

    ## service
    services.firefly-iii = {
      enable = true;
      group = lib.mkForce "nginx";

      settings = commonConf // {
        APP_KEY_FILE = config.sops.secrets."${category}/${app}/app_key".path;

        DB_CONNECTION = "pgsql";
        DB_SOCKET = "/run/postgresql";
        DB_PORT = 5432;
        DB_DATABASE = "firefly-iii";

        DEFAULT_LOCALE = "en_AU.UTF-8"; # Sensible data formats

        ENABLE_EXTERNAL_MAP = "true";
      };
    };

    services.firefly-iii-data-importer = {
      enable = true;
      group = lib.mkForce "nginx";
      virtualHost = "firefly-iii-importer.trux.dev";
      settings = commonConf // {
        FIREFLY_III_URL = "https://firefly-iii.trux.dev";
        EXPECT_SECURE_URL = "true";
        FIREFLY_III_CLIENT_ID = "5";

        # TODO
        #              IGNORE_DUPLICATE_ERRORS = "true";
      };
    };

    # systemd.services.firefly-iii = {
    #   after = [ "postgresql.service" ];
    #   requires = [ "postgresql.service" ];
    # };

    services.postgresql = {
      ensureDatabases = [ app ];
      ensureUsers = [
        {
          name = app;
          ensureDBOwnership = true;
        }
      ];
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
      root = "${config.services.firefly-iii.package}/public";
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.php?$query_string";
          index = "index.php";
          extraConfig = ''
            sendfile off;
          '';
        };
        "~ \\.php$" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/fastcgi_params ;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_param modHeadersAvailable true; #Avoid sending the security headers twice
            fastcgi_pass unix:${config.services.phpfpm.pools.firefly-iii.socket};
          '';
        };
      };
    };
    services.nginx.virtualHosts."firefly-iii-importer.trux.dev" = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      root = "${config.services.firefly-iii-data-importer.package}/public";
      locations = {
        "/" = {
          tryFiles = "$uri $uri/ /index.php?$query_string";
          index = "index.php";
          extraConfig = ''
            sendfile off;
          '';
        };
        "~ \\.php$" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/fastcgi_params ;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_param modHeadersAvailable true;
            fastcgi_pass unix:${config.services.phpfpm.pools.firefly-iii-data-importer.socket};
          '';
        };
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

    services.postgresqlBackup = {
      databases = [ app ];
    };

  };
}
