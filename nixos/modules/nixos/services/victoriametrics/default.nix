{ lib
, config
, pkgs
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "victoriametrics";
  category = "services";
  description = "Metric storage";
  # image = "";
  user = app; #string
  group = app; #string
  port = 8428; #int
  portAM = 9093; #int
  portVAM = 8880; #int

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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; }];
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
        groups = [{
          name = "alerting-rules";
          rules = import ./alert-rules.nix { inherit lib; };
        }];
      };
    };

    services.prometheus.alertmanager = {
      enable = true;
      environmentFile = config.sops.secrets."services/alertmanager/env".path;
      webExternalUrl = "https://alertmanager.${config.networking.domain}";
      configuration = {
        route = {
          receiver = "pushover";
          group_by = [ "alertname" "job" ];
          group_wait = "5m";
          group_interval = "1m";
          repeat_interval = "24h";
        };
        receivers = [
          {
            name = "pushover";
            pushover_configs = [{
              user_key = "$PUSHOVER_USER_KEY";
              token = "$PUSHOVER_TOKEN";
              priority = ''{{ if eq .Status " firing " }}1{{ else }}0{{ end }}'';
              title = ''{{ .CommonLabels.alertname }} [{{ .Status | toUpper }}{{ if eq .Status " firing " }}:{{ .Alerts.Firing | len }}{{ end }}]'';
              message = ''
                {{- range .Alerts }}
                  {{- if ne .Annotations.description "" }}
                    {{ .Annotations.description }}
                  {{- else if ne .Annotations.summary "" }}
                    {{ .Annotations.summary }}
                  {{- else if ne .Annotations.message "" }}
                    {{ .Annotations.message }}
                  {{- else }}
                    Alert description not available
                  {{- end }}
                  {{- if gt (len .Labels.SortedPairs) 0 }}
                    <small>
                    {{- range .Labels.SortedPairs }}
                      <b>{{ .Name }}:</b> {{ .Value }}
                    {{- end }}
                    </small>
                  {{- end }}
                {{- end }}
              '';
              send_resolved = true;
              html = true;

            }];
          }
          {
            name = "default";
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
