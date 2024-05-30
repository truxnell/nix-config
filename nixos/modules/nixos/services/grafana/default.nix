{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "grafana";
  category = "services";
  description = "Metrics graphing";
  # image = "";
  user = app; #string
  group = app; #string
  port = 3090; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };


    ## service
    services.grafana = {

      enable = true;
      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-clock-panel
      ];

      settings = {
        database.wal = true;

        server = {
          http_port = port;
          http_addr = "127.0.0.1";
          enable_gzip = true;
          inherit (config.networking) domain;
        };

        analytics = {
          check_for_updates = false;
          feedback_links_enabled = false;
          reporting_enabled = false;
        };
      };
      provision = {
        enable = true;
        datasources.settings = {
          datasources = [
            {
              uid = "victoria-metrics";
              name = "VictoriaMetrics";
              type = "prometheus";
              access = "proxy";
              isDefault = true;
              url = "http://localhost${config.services.victoriametrics.listenAddress}";
            }
          ];
        };
        dashboards.settings.providers =
          let
            makeReadOnly = x: lib.pipe x [
              builtins.readFile
              builtins.fromJSON
              (x: x // { editable = false; })
              builtins.toJSON
              (pkgs.writeText (builtins.baseNameOf x))
            ];
          in
          [
            {
              name = "PostgreSQL";
              type = "file";
              url = "https://grafana.com/api/dashboards/9628/revisions/7/download";
              options.path = makeReadOnly ./dashboards/postgres.json;
            }
            {
              name = "Node";
              type = "file";
              url = "https://raw.githubusercontent.com/rfmoz/grafana-dashboards/master/prometheus/node-exporter-full.json";
              options.path = makeReadOnly ./dashboards/node.json;
            }
            {
              name = "Nginx";
              type = "file";
              url = "https://raw.githubusercontent.com/nginxinc/nginx-prometheus-exporter/main/grafana/dashboard.json";
              options.path = makeReadOnly ./dashboards/nginx.json;
            }
            {
              name = "Redis";
              type = "file";
              url = "https://raw.githubusercontent.com/oliver006/redis_exporter/master/contrib/grafana_prometheus_redis_dashboard.json";
              options.path = ./dashboards/redis.json;
            }
            {
              name = "Gatus";
              type = "file";
              url = "https://github.com/TwiN/gatus/blob/master/.examples/docker-compose-grafana-prometheus/grafana/provisioning/dashboards/gatus.json";
              options.path = ./dashboards/gatus.json;
            }
            # Unifi
            # ref: https://unpoller.com/docs/install/grafana
            # TODO: can we enabled/disable these based on unpoller setup cross/device?
            {
              name = "Unifi-Clients";
              type = "file";
              url = "https://grafana.com/api/dashboards/11310/revisions/5/download";
              options.path = ./dashboards/unifi-clients.json;
            }
            # {
            #   name = "Unifi-DPI";
            #   type = "file";
            #   url = "https://grafana.com/api/dashboards/11310/revisions/5/download";
            #   options.path = ./dashboards/unifi-dpi.json;
            # }
            # {
            #   name = "Unifi-sites";
            #   type = "file";
            #   url = "https://grafana.com/api/dashboards/11311/revisions/5/download";
            #   options.path = ./dashboards/unifi-sites.json;
            # }
            {
              name = "Unifi-UAP";
              type = "file";
              url = "https://grafana.com/api/dashboards/undefined/revisions/0/download";
              options.path = ./dashboards/unifi-uap.json;
            }
            {
              name = "Unifi-USG";
              type = "file";
              url = "https://grafana.com/api/dashboards/undefined/revisions/0/download";
              options.path = ./dashboards/unifi-usg.json;
            }
            {
              name = "Unifi-USW";
              type = "file";
              url = "https://grafana.com/api/dashboards/undefined/revisions/0/download";
              options.path = ./dashboards/unifi-usw.json;
            }
            {
              name = "Unifi-clients";
              type = "file";
              url = "https://grafana.com/api/dashboards/11315/revisions/9/download";
              options.path = ./dashboards/unifi-clients.json;
            }
            {
              name = "smartctl";
              type = "file";
              url = "https://grafana.com/api/dashboards/20204/revisions/1/download";
              options.path = ./dashboards/smartctl.json;
            }
            {
              name = "nextdns";
              type = "file";
              url = "https://github.com/truxnell/home-cluster/blob/0f7b47a9fec9419a4c5d6b5c4a4ae219ad342c1c/kubernetes/hegira/apps/monitoring/nextdns-exporter/trusted/externalsecret.yaml";
              options.path = ./dashboards/nextdns.json;
            }



          ];

      };

    };



    # homepage integration
    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${url}";
          inherit description;
        };
      }
    ];

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
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
    warnings = [
      (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
        "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (config.lib.mySystem.mkRestic
      {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      });


    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };



  };
}
