{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.grafana;
  app = "grafana";
  category = "services";
  description = "Metric visualisation";
  user = app; #string
  group = app; #string
  port = 2342; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.development then "-dev" else "");
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
      #   prometheus = mkOption
      #     {
      #       type = lib.types.bool;
      #       description = "Enable prometheus scraping";
      #       default = true;
      #     };
      addToDNS = mkOption
        {
          type = lib.types.bool;
          description = "Add to DNS list";
          default = true;
        };
      development = mkOption
        {
          type = lib.types.bool;
          description = "Development instance";
          default = false;
        };
      backups = mkOption
        {
          type = lib.types.bool;
          description = "Enable local backups";
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

    ## service
    services.grafana = {
      inherit port;
      enable = true;
      domain = host;
      addr = "127.0.0.1";
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
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    warnings = [
      (mkIf (!cfg.backups && config.mySystem.purpose != "Development")
        "WARNING: Local backups for ${app} are disabled!")
    ];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;

      };


  };
}
