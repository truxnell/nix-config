{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "rxresume";
  category = "services";
  description = "Resume builder";
  image = "ghcr.io/amruthpillai/reactive-resume:v4.4.5@sha256:feb1e7b812b23105a84430630952e65c873606256ac91208af412e1f5e347411";
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

    # enable browserless container on this system
    mySystem.services.browserless-chrome.enable = true;

    users.users.truxnell.extraGroups = [ (builtins.toString config.users.groups.rxresume.gid) ];

    users.users = {
      rxresume = {
        group = "rxresume";
        home = "/var/lib/rxresume/";
        uid = 319;
      };
    };

    users.groups = {
      rxresume.gid = 319;
    };

    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image;
      user = "0"; # :(
      group = "0"; # :(
      env = {
        PORT = "3000";
        NODE_ENV = "production";
        PUBLIC_URL = "https://rxresume.${config.networking.domain}";
        STORAGE_URL = "https://s3.${config.networking.domain}/rxresume";
        CHROME_URL = "ws://browserless-chrome:3000/chrome";
        DATABASE_URL = "postgresql://rxresume@localhost/rxresume?host=/run/postgresql";
        MAIL_FROM = "noreply@localhost";
        STORAGE_ENDPOINT = "s3.trux.dev";
        STORAGE_PORT = "443";
        STORAGE_BUCKET = "rxresume";
        STORAGE_USE_SSL = "true";
      };
      volumes = [
        "/run/postgresql:/run/postgresql"
      ];

      envFiles = [
        config.sops.secrets."${category}/${app}/env".path
      ];
      dependsOn = [ "browserless-chrome" ];
    };

    systemd.services.podman-rxresume={
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };


    # homepage integration
    mySystem.services.homepage.infrastructure = mkIf
      cfg.addToHomepage
      [
        {
          ${app} = {
            icon = "${app}.svg";
            href = "https://${url}";
            inherit description;
          };
        }
      ];

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf
      cfg.monitor
      [
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
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
        proxyWebsockets = true;
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

    services.restic.backups = mkIf
      cfg.backup
      (config.lib.mySystem.mkRestic
        {
          inherit app user;
          paths = [ appFolder ];
          inherit appFolder;
        });

    # ensure postgresql setup
    services.postgresql = {
      ensureDatabases = [ app ];
      ensureUsers = [{
        name = app;
        ensureDBOwnership = true;
      }];
    };


    services.postgresqlBackup = {
      databases = [ app ];
    };

  };
}
