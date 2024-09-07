{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "browserless-chrome";
  category = "services";
  description = "docker based browsers for automation";
  image = "ghcr.io/browserless/chrome";
  user = "kah"; #string
  group = "kah"; #string
  port = 3000; #int
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
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    # users.users.truxnell.extraGroups = [ group ];


    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    # environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
    #   directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    # };


    ## service
    # services.test= {
    #   enable = true;
    # };

    ## OR

    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image;
      user = "0"; #:()
      group = "0"; #:()
      env = {
        TIMEOUT = "90000";
        CONCURRENT = "15";
        TOKEN =  "derpyderpderp";
        EXIT_ON_HEALTH_FAILURE = "true";
        PRE_REQUEST_HEALTH_CHECK = "true";
        # SCREEN_WIDTH = "1920";
        # SCREEN_HEIGHT = "1024";
        # SCREEN_DEPTH = "16";
        # ENABLE_DEBUGGER = "false";
        # PREBOOT_CHROME = "true";
        # CHROME_REFRESH_TIME = "600000";
        # DEFAULT_BLOCK_ADS = "true";
        # DEFAULT_STEALTH = "true";
        # CORS = "true";
      };
      # envFiles = [
      #   config.sops.secrets."${category}/${app}/env".path
      # ];

    };


    # homepage integration
    # mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
    #   {
    #     ${app} = {
    #       icon = "${app}.svg";
    #       href = "https://${url}";
    #       inherit description;
    #     };
    #   }
    # ];

    ### gatus integration
    # mySystem.services.gatus.monitors = mkIf cfg.monitor [
    #   {
    #     name = app;
    #     group = "${category}";
    #     url = "https://${url}/docs";
    #     interval = "1m";
    #     conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    #   }
    # ];

    ### Ingress
    # services.nginx.virtualHosts.${url} = {
    #   forceSSL = true;
    #   useACMEHost = config.networking.domain;
    #   locations."^~ /" = {
    #     proxyPass = "http://127.0.0.1:${builtins.toString port}";
    #     extraConfig = "resolver 10.88.0.1;";
    #   };
    # };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    # warnings = [
    #   (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
    #     "WARNING: Backups for ${app} are disabled!")
    # ];

    # services.restic.backups = mkIf cfg.backup (config.lib.mySystem.mkRestic
    #   {
    #     inherit app user;
    #     paths = [ appFolder ];
    #     inherit appFolder;
    #   });


    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };



  };
}
