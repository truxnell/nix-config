{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "redlib";
  category = "services";
  description = "reddit alternative frontend";
  image = "quay.io/redlib/redlib:latest@sha256:b0586a99faa185ed6629b9aa64dc37f95414b862724f2c76952cdf89ca531ca0";
  user = "redlib"; #string
  group = "redlib"; #string
  port = 8080; #int
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


    # Folder perms
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    ## service
    # services.test= {
    #   enable = true;
    # };

    ## container
    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image user group;
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
        url = "https://${url}/settings"; # settings page as pinging the main page is slow/creates requests
        interval = "1m";
        conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    # warnings = [
    #   (mkIf (!cfg.backups && config.mySystem.purpose != "Development")
    #     "WARNING: Local backups for ${app} are disabled!")
    # ];

    # services.restic.backups = config.lib.mySystem.mkRestic
    #   {
    #     inherit app user;
    #     paths = [ appFolder ];
    #     inherit appFolder;

    #   };


  };
}
