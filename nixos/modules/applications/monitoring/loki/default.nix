{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "loki";
  category = "services";
  description = "Log aggregation system";
  user = "loki";
  group = "loki";
  port = 3100;
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
      default = false; # Logs are ephemeral
    };
    retention = mkOption {
      type = lib.types.str;
      description = "Log retention period";
      default = "720h"; # 30 days default
    };
  };

  config = mkIf cfg.enable {
    # User/Group Management
    users.users.truxnell.extraGroups = [ group ];
    users.users.${user} = {
      isSystemUser = true;
      inherit group;
    };
    users.groups.${group} = { };

    # Ensure Loki directories exist with correct permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/loki 0750 ${user} ${group} - -"
      "d /var/lib/loki/chunks 0750 ${user} ${group} - -"
      "d /var/lib/loki/index 0750 ${user} ${group} - -"
      "d /var/lib/loki/rules 0750 ${user} ${group} - -"
      "d /var/lib/loki/cache 0750 ${user} ${group} - -"
      "d /var/lib/loki/compactor 0750 ${user} ${group} - -"
    ];

    services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;

          server = {
            http_listen_port = 3100;
          };

          common = {
            instance_addr = "::1";
            path_prefix = "/var/lib/loki";
            storage.filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
            replication_factor = 1;
            ring.kvstore.store = "inmemory";
          };

          schema_config.configs = [
            {
              # https://grafana.com/docs/loki/latest/operations/storage/schema/
              # DONT CHANGE THIS
              from = "2020-10-24";
              index = {
                period = "24h";
                prefix = "index_";
              };
              object_store = "filesystem";
              schema = "v13";
              store = "tsdb";
            }
          ];

          limits_config = {
            retention_period = cfg.retention;
            allow_structured_metadata = true;
            # Increase ingestion limits for homelab with multiple hosts
            ingestion_rate_mb = 50; # MB per second (default: 4)
            ingestion_burst_size_mb = 100; # Burst size in MB (default: 6)
            max_streams_per_user = 10000; # Max streams per user (default: 10000)
            max_line_size = "256KB"; # Max line size (default: 256KB)
            max_query_length = "721h"; # Max query range (default: 721h)
            max_query_parallelism = 32; # Max query parallelism (default: 32)
          };

          storage_config = {
            filesystem = {
              directory = "/var/lib/loki/chunks";
            };
          };

          compactor = {
            retention_enabled = true;
            delete_request_store = "filesystem";
          };

          analytics.reporting_enabled = false;
        };
      };
    # Monitoring Integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}/ready";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 2000"
        ];
      }
    ];

    # Reverse Proxy Configuration
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_read_timeout 300;
          proxy_connect_timeout 300;
          proxy_send_timeout 300;
        '';
      };
    };

    # Firewall configuration for internal access
    networking.firewall.allowedTCPPorts = [ port ];

  };
}
