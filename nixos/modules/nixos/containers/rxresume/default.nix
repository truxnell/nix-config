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
  image = "ghcr.io/amruthpillai/reactive-resume:v4.1.3@sha256:8aeff4b2ac5d9cab104733cd6712ad6633928544bf5968c696df4078770d0cc2";
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
    # sops.secrets."${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "${app}.service" ];
    # };

    # enable browserless container on this system
    mySystem.services.browserless-chrome.enable = true;

    users.users.truxnell.extraGroups = [ users.groups.rxresume.gid ];

    users.users = {
      rxresume = {
        inherit (cfg) group;
        home = cfg.dataDir;
        uid = config.ids.uids.sonarr;
      };
    };

    users.groups = mkIf (cfg.group == "sonarr") {
      rxresume.gid = "1024";
    };

    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image user group;
      env = {
        # -- Environment Variables --
        PORT = "3000";
        NODE_ENV = "production";

        # -- URLs --
        PUBLIC_URL = "https://localhost:3000";
        STORAGE_URL = "http://s3.trux.dev:9000/rxresume";

        # -- Printer (Chrome) --
        CHROME_TOKEN = "MBUwBVo9MLf!$%gKwgKZHf^s&Br&k8$F";
        CHROME_URL = "ws://127.0.0.1:3001";

        # -- Database (Postgres) --
        # DATABASE_URL = "postgresql://postgres:postgres@postgres:5432/postgres";
        DATABASE_URL = "socket://rxresume:@/run/postgresql?db=rxresume";

        # -- Auth --
        ACCESS_TOKEN_SECRET = "t3r*ve8BAqEPi4$Eh3MwvWfSu!Xz35*@";
        REFRESH_TOKEN_SECRET = "@@nCvdqY@LBjFWHfk%g6Wonq&Vgm55p5";

        # -- Emails --
        MAIL_FROM = "noreply@localhost";
        # SMTP_URL = "smtp://user:pass@smtp:587 # Optional";

        # -- Storage (Minio) --
        STORAGE_ENDPOINT = "s3.trux.dev";
        STORAGE_PORT = "9000";
        # STORAGE_REGION = "us-east-1";
        STORAGE_BUCKET = "default";
        STORAGE_ACCESS_KEY = "KQ4xdrKb472i7^F^*^kpE8VPz%EDie8M";
        STORAGE_SECRET_KEY = "GdieoKqz5t%D53J$bjhNvtM3VM@JdKoy";
        STORAGE_USE_SSL = "true";

      };
      ports = [ ];
      environmentFiles = [ ];
      dependsOn = [ "podman-browserless-chrome" ];
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
