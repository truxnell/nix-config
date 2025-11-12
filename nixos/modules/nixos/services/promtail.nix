{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.services.promtail;
  lokiHost = "loki.${config.networking.domain}";
in
{
  options.mySystem.services.promtail = {
    enable = mkEnableOption "promtail log forwarding";
    
    lokiUrl = mkOption {
      type = lib.types.str;
      description = "Loki server URL";
      default = "https://${lokiHost}/loki/api/v1/push";
    };
    
    extraScrapeConfigs = mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Additional scrape configurations";
      default = [];
    };
    
    logLevel = mkOption {
      type = lib.types.str;
      description = "Log level for promtail";
      default = "info";
    };
  };

  config = mkIf cfg.enable {
    services.promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
          log_level = cfg.logLevel;
        };
        
        positions = {
          filename = "/var/lib/promtail/positions.yaml";
        };
        
        clients = [{
          url = cfg.lokiUrl;
          # Add retry configuration for reliability
          backoff_config = {
            min_period = "500ms";
            max_period = "5m";
            max_retries = 10;
          };
        }];
        
        scrape_configs = [
          # Systemd Journal Logs
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              # Extract service name from systemd unit
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
              # Extract hostname
              {
                source_labels = ["__journal__hostname"];
                target_label = "hostname"; 
              }
              # Map priority to level
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "0";
                replacement = "emergency";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "1";
                replacement = "alert";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "2";
                replacement = "critical";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "3";
                replacement = "error";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "4";
                replacement = "warning";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "5";
                replacement = "notice";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "6";
                replacement = "info";
              }
              {
                source_labels = ["__journal_priority"];
                target_label = "level";
                regex = "7";
                replacement = "debug";
              }
              # Extract process name
              {
                source_labels = ["__journal__comm"];
                target_label = "command";
              }
              # Extract systemd slice
              {
                source_labels = ["__journal__systemd_slice"];
                target_label = "slice";
              }
            ];
            pipeline_stages = [
              # Detect log level from content and override incorrect systemd priority
              # This fixes container logs (conmon) that are incorrectly classified as error
              # Step 1: Try to extract level from JSON structured logs
              {
                match = {
                  selector = ''{unit=~".+"}'';
                  stages = [
                    {
                      json = {
                        expressions = {
                          content_level = "level";
                          msg = "msg";
                          timestamp = "timestamp";
                        };
                      };
                    }
                  ];
                };
              }
              # Step 2: If no JSON level, detect from text patterns (level=info, INFO, etc.)
              {
                regex = {
                  expression = ''(?i)(?:^|\s|\[)(?:level[=:]?\s*)?(?P<text_level>emergency|alert|critical|error|warning|warn|notice|info|debug|trace)(?:\s|$|\[|:|])'';
                };
              }
              # Step 3: Use detected level from content if available, otherwise keep systemd priority
              # This prioritizes: JSON level > regex level > systemd priority
              {
                template = {
                  source = "detected_level";
                  template = ''{{ if .content_level }}{{ .content_level | ToLower }}{{ else if .text_level }}{{ .text_level | ToLower }}{{ else }}{{ .level }}{{ end }}'';
                };
              }
              {
                labels = {
                  level = "detected_level";
                };
              }
            ];
          }
          
          # Nginx access logs (if nginx is enabled) - JSON format
          (mkIf config.services.nginx.enable {
            job_name = "nginx-access";
            static_configs = [{
              targets = ["localhost"];
              labels = {
                job = "nginx-access";
                host = config.networking.hostName;
                __path__ = "/var/log/nginx/access.log";
              };
            }];
            pipeline_stages = [
              # Parse JSON nginx logs
              {
                json = {
                  expressions = {
                    method = "method";
                    status = "status";
                    remote_addr = "remote_addr";
                    request_uri = "request_uri";
                    request_time = "request_time";
                    host_header = "host";
                    user_agent = "http_user_agent";
                    upstream_response_time = "upstream_response_time";
                  };
                };
              }
              {
                labels = {
                  method = null;
                  status = null;
                  host_header = null;
                };
              }
            ];
          })
          
          # Nginx error logs (if nginx is enabled)
          (mkIf config.services.nginx.enable {
            job_name = "nginx-error";
            static_configs = [{
              targets = ["localhost"];
              labels = {
                job = "nginx-error";
                host = config.networking.hostName;
                __path__ = "/var/log/nginx/error.log";
              };
            }];
          })
          
          # PostgreSQL logs (if postgresql is enabled)
          (mkIf config.services.postgresql.enable {
            job_name = "postgresql";
            static_configs = [{
              targets = ["localhost"];
              labels = {
                job = "postgresql";
                host = config.networking.hostName;
                __path__ = "/var/log/postgresql/*.log";
              };
            }];
          })
          
        ] ++ cfg.extraScrapeConfigs;
      };
    };

    # Ensure promtail has permissions to read journal and log files
    systemd.services.promtail.serviceConfig = {
      SupplementaryGroups = [ "systemd-journal" "nginx" ];
    };

    # Create positions directory
    systemd.tmpfiles.rules = [
      "d /var/lib/promtail 0755 promtail promtail -"
    ];

    # Firewall configuration (promtail metrics endpoint)
    networking.firewall.allowedTCPPorts = [ 9080 ];

    # User and group for promtail
    users.users.promtail = {
      isSystemUser = true;
      group = "promtail";
      extraGroups = [ "systemd-journal" ];
    };
    users.groups.promtail = {};
  };
}