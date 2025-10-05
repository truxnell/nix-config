{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "victoriametrics";
  category = "services";
  description = "Metric storage";
  # image = "";
  user = app; # string
  group = app; # string
  port = 8428; # int
  portAM = 9093; # int
  portVAM = 8880; # int
  alertmanagerNtfyPort = 8087;

  appFolder = "/var/lib/private/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  hostAM = "alertmanager" + (if cfg.dev then "-dev" else "");
  urlAM = "${hostAM}.${config.networking.domain}";
  hostVAM = "vmalert" + (if cfg.dev then "-dev" else "");
  urlVAM = "${hostVAM}.${config.networking.domain}";

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
    sops.secrets."services/alertmanager/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      mode = "660";
      restartUnits = [ "alertmanager.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [ { directory = appFolder; } ];
        };

    ## service
    services.victoriametrics = {
      enable = true;
      retentionPeriod = "12";
    };

    services.vmalert = {
      enable = true;
      settings = {
        "datasource.url" = "http://localhost:${builtins.toString port}";
        "notifier.url" = [ "http://localhost:${builtins.toString portAM}" ];
      };
      rules = {
        groups = [
          {
            name = "alerting-rules";
            rules = import ./alert-rules.nix { inherit lib; };
          }
        ];
      };
    };

    services.prometheus.alertmanager = {
      enable = true;
      environmentFile = config.sops.secrets."services/alertmanager/env".path;
      webExternalUrl = "https://alertmanager.${config.networking.domain}";
      configuration = {
        route = {
          receiver = "ntfy";
        };
        receivers = [
          {
              name = "ntfy";
              webhook_configs = [ { url = "http://127.0.0.1:${toString alertmanagerNtfyPort}/hook"; } ];
          }
          {
            name = "default";
          }
        ];
      };
    };

  services.prometheus.alertmanager-ntfy = {
    enable = true;
    settings = {
      http.addr = "127.0.0.1:${toString alertmanagerNtfyPort}";
      ntfy = {
        baseurl = "https://ntfy.${config.networking.domain}";
        notification = {
          topic = "alertmanager";
          priority = ''
            status == "firing" ? "high" : "default"
          '';
          tags = [
            {
              tag = "+1";
              condition = ''status == "resolved"'';
            }
            {
              tag = "rotating_light";
              condition = ''status == "firing"'';
            }
          ];
          templates = {
            title = ''{{ if eq .Status "resolved" }}Resolved: {{ end }}{{ index .Annotations "summary" }}'';
            description = ''{{ index .Annotations "description" }}'';
          };
        };
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
    # victoriametrics
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
      };
    };

    # alertmanager
    services.nginx.virtualHosts.${urlAM} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString portAM}";
      };
    };

    # vmalert
    services.nginx.virtualHosts.${urlVAM} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString portVAM}";
        proxyWebsockets = true;
      };
    };

    ### firewall config

    networking.firewall = {
      allowedTCPPorts = [ port ];
      # allowedUDPPorts = [ port ];
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
      }http://localhost:9100/metrics
    );

    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };

  };
}
