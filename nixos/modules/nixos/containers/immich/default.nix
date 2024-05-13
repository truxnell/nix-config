{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "immich";
  category = "services";
  description = "Photo managment";
  # image = "";
  user = "kah"; #string
  group = "kah"; #string
  port = 8080; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  environment = {
    DB_DATA_LOCATION = "/run/postgresql";
    DB_USERNAME = "postgres";
    DB_PASSWORD = "dummy";
    DB_DATABASE_NAME = "immich";
    REDIS_SOCKET = "/run/redis-immich/redis.sock";
    DB_URL = "socket://immich:@/run/postgresql?db=immich";
  };
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

    users = {
      users = {

        # Create immich user
        immich = {
          isSystemUser = true;
          group = "immich";
          description = "Immich daemon user";
          # home = cfg.dataDir;
          uid = 390;
        };

        truxnell.extraGroups = [ "immich" ];
        # Add admins to the immich group
      };

      # Create immich group
      groups.immich = {
        gid = 390;
      };

    };


    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers =
      {
        immich-server = {
          image = "ghcr.io/immich-app/immich-server:v1.103.1";
          cmd = [ "start-server.sh" "immich" ];
          # autoStart = false;

          user = "390:390";

          inherit environment;

          volumes = [
            "/run/postgresql:/run/postgresql"
            "/run/redis-immich:/run/redis-immich"
            "${config.mySystem.nasFolder}/photos/upload:/usr/src/app/upload"
          ];

          # extraOptions =  [ "--network=immich" ];

        };

      };

    services.redis.servers.immich = {
      enable = true;
      user = "immich";
    };

    services.postgresql = {

      enable = true;
      ensureUsers = [{
        name = "immich";
        ensureDBOwnership = true;
      }];
      ensureDatabases = [ "immich" ];

      # Allow connections from any docker IP addresses
      authentication = mkBefore "host immich immich 10.88.0.0/12 md5";

      # # Postgres extension pgvecto.rs required since Immich 1.91.0
      # extraPlugins = [
      #   (pkgs.pgvecto-rs.override rec {
      #     postgresql = config.services.postgresql.package;
      #     stdenv = postgresql.stdenv;
      #   })
      # ];
      # settings.shared_preload_libraries = "vectors.so";

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


    services.postgresqlBackup = {
      databases = [ app ];
    };



  };
}
