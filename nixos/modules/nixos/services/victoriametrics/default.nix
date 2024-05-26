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
  appFolder = "/var/lib/private/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  hostVmAgent = "vmagent" + (if cfg.dev then "-dev" else "");
  urlVmAgent = "${hostVmAgent}.${config.networking.domain}";

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
    sops.secrets."services/alertmanager" = {
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; }];
    };


    ## service
    services.victoriametrics = {
      enable = true;
      retentionPeriod = 12;
    };

    services.prometheus.alertmanager = {
      enable = true;
      environmentFile = config.sops.secrets."services/alertmanager".path;
      webExternalUrl = "https://alertmanager.${config.networking.domain}";
      configuration = {
        route = {
          receiver = "default";
          group_by = [ "alertname" "job" ];
          group_wait = "5m";
          group_interval = "1m";
          repeat_interval = "24h";
          routes = [{ }
            {
              group_by = [ "instance" ];
              group_wait = "30s";
              group_interval = "2m";
              repeat_interval = "2h";
              receiver = "all";
            }];
        };
        receivers = [
          {
            # route that goes nowhere
            # to suppress always-on watchdog alert
            name = "null";
          }
          {
            name = "pushover";
            pushover_configs = [{
              user_key = "$PUSHOVER_USER_KEY";
              token = "$PUSHOVER_TOKEN";
              priority = "{{ if eq .Status " firing " }}1{{ else }}0{{ end }}";
              title = "{{ .CommonLabels.alertname }} [{{ .Status | toUpper }}{{ if eq .Status " firing " }}:{{ .Alerts.Firing | len }}{{ end }}]";
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
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
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
