{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "miniflux";
  category = "services";
  description = "Minimalist feed reader";
  # image = "%{image}";
  user = app; #string
  group = app; #string
  port = 8072; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  databaseUrl = "user=miniflux host=/run/postgresql dbname=miniflux";

  miniflux-reset-feed-errors =
    pkgs.writeShellScriptBin "miniflux-reset-feed-errors" ''
      ${config.services.miniflux.package}/bin/miniflux -reset-feed-errors
    '';
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;
        };
      prometheus = mkOption
        {
          type = lib.types.bool;
          description = "Enable prometheus scraping";
          default = true;
        };
      addToDNS = mkOption
        {
          type = lib.types.bool;
          description = "Add to DNS list";
          default = true;
        };
      dev = mkOption
        {
          type = lib.types.bool;
          description = "Development instance";
          default = false;
        };
      backup = mkOption
        {
          type = lib.types.bool;
          description = "Enable backups";
          default = true;
        };

    };

  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];
    users.users.miniflux = {
      isSystemUser = true;
      group = "miniflux";
    };

    users.groups.miniflux = { };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    ## service
    services.miniflux = {
      enable = true;
      adminCredentialsFile = config.sops.secrets."${category}/${app}/env".path;
      config = {
        LISTEN_ADDR = "localhost:${builtins.toString port}";
        DATABASE_URL = databaseUrl;
        RUN_MIGRATIONS = lib.mkForce "1";
        CREATE_ADMIN = lib.mkForce "1";
        YOUTUBE_EMBED_URL_OVERRIDE = "https://invidious.${config.networking.domain}/"; #TODO only if invidious enabled on machine somewhere
        METRICS_COLLECTOR = "true";
      };
    };

    # automatically reset feed errors regular
    systemd.services.miniflux-reset-feed-errors = {
      description = "Miniflux reset feed errors";
      wantedBy = [ "multi-user.target" ];
      requires = [ "${app}.service" ];
      after = [ "network.target" "${app}.service" ];
      environment.DATABASE_URL = databaseUrl;
      startAt = "daily";
      serviceConfig = {
        Type = "oneshot";
        User = "miniflux";
        DynamicUser = true;
        RuntimeDirectory = "miniflux"; # Creates /run/miniflux.
        EnvironmentFile = config.sops.secrets."${category}/${app}/env".path;
        ExecStart = ''
          ${miniflux-reset-feed-errors}/bin/miniflux-reset-feed-errors
        '';
      };
    };

    # homepage integration
    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${url}";
          inherit description;
          widget = {
            type = "miniflux";
            url = "https://${url}";
            key = "{{HOMEPAGE_VAR_MINIFLUX_API_KEY}}";
          };
        };
      }
    ];

    # ensure postgresql setup

    services.postgresql = {
      ensureDatabases = [ app ];
      ensureUsers = [{
        name = app;
        ensureDBOwnership = true;
      }];
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}/metrics";
        interval = "1m";
        conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
      };
    };

# Victoriametrics scraping
    services.vmagent = {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = app;
            # scrape_timeout = "40s";
            static_configs = [
              {
                targets = [ "https://${app}.${config.mySystem.domain}/metrics" ];
              }
            ];
          }
        ];
      };
    };


    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    ### backups
    warnings = [
      (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
        "WARNING: Backups for ${app} are disabled!")
      (mkIf (!config.services.postgresql.enable)
        "WARNING: Postgres is not enabled on host for ${app}!")
    ];


    # services.restic.backups = mkIf cfg.backup (config.lib.mySystem.mkRestic
    #   {
    #     inherit app user;
    #     paths = [ appFolder ];
    #     inherit appFolder;
    #   });

    services.postgresqlBackup = mkIf
      cfg.backup
      {
        databases = [ app ];
      };



  };
}
