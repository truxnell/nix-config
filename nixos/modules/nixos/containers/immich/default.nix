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
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      group = group;
      restartUnits = [ "${app}.service" ];
    };

    # users = {
    #   users = {

    #     # Create immich user
    #     immich = {
    #       isSystemUser = true;
    #       group = "immich";
    #       description = "Immich daemon user";
    #       # home = cfg.dataDir;
    #       uid = 390;
    #     };

    #     truxnell.extraGroups = [ "immich" ];
    #     # Add admins to the immich group
    #   };

    #   # Create immich group
    #   groups.immich = {
    #     gid = 390;
    #   };

    # };


    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers =
      {
        # immich-server = {
        #   image = "ghcr.io/immich-app/immich-server:v1.105.1";
        #   cmd = [ "start.sh" "immich" ];
        #   inherit environment;
        #   volumes = [
        #     "/run/redis-immich:/run/redis-immich"
        #     "/etc/localtime:/etc/localtime:ro"
        #     "${config.mySystem.nasFolder}/photos/upload:/usr/src/app/upload"
        #   ];
        #   dependsOn = [ "redis-immich.service" "podman-immich-postgres.service" ];
        # };

        # immich-micoservices = {
        #   image = "ghcr.io/immich-app/immich-server:v1.105.1";
        #   cmd = [ "start.sh" "microservices" ];
        #   inherit environment;
        #   volumes = [
        #     "/run/redis-immich:/run/redis-immich"
        #     "/etc/localtime:/etc/localtime:ro"
        #     "${config.mySystem.nasFolder}/photos/upload:/usr/src/app/upload"
        #   ];
        #   dependsOn = [ "redis-immich.service" "podman-immich-postgres.service" ];
        # };


        immich-machine-learning = {
          image = "ghcr.io/immich-app/immich-machine-learning:v1.105.1";
          inherit environment;
          volumes = [
            "/run/postgresql:/run/postgresql"
            "${config.mySystem.nasFolder}/photos/upload:/usr/src/app/upload"
            "/var/lib/immich/machine-learning:/cache"
          ];
        };

        immich-postgres = {
          image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
          environmentFiles = [ config.sops.secrets."${category}/${app}/env".path ];
          environment = {
            POSTGRES_INITDB_ARGS = "--data-checksums";
          };
          cmd = [
            "postgres"
            "-c"
            "shared_preload_libraries=vectors.so"
            "-c"
            ''search_path="$$user", public, vectors''
            "-c"
            "logging_collector=on"
            "-c"
            "max_wal_size=2GB"
            "-c"
            "shared_buffers=512MB"
            "-c"
            "wal_compression=on"
          ];
          volumes = [ "/var/lib/immich/postgres/:/var/lib/postgresql/data" ];
        };
      };


    services.redis.servers.immich = {
      enable = true;
      user = "immich";
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
