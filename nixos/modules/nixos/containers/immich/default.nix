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
  port = 2283; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  environment = {
    DB_HOSTNAME = "immich-postgres";
    REDIS_HOSTNAME = "immich-redis";
    IMMICH_METRICS = "true";
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
      inherit group;
      restartUnits = [ "${app}-server.service" "${app}-postgres.service" ];
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
      "d ${appFolder}/machine-learning 0750 ${user} ${group} -"
      "d ${appFolder}/postgres 0750 acme acme -"

    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers =
      {
        immich-server = {
          image = "ghcr.io/immich-app/immich-server:v1.125.7";
          environmentFiles = [ config.sops.secrets."${category}/${app}/env".path ];
          inherit environment;
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "/zfs/photos/immich/:/usr/src/app/upload"
          ];
          dependsOn = [ "immich-redis" "immich-postgres" ];
          ports = [ "${builtins.toString port}:${builtins.toString port}" ];
          extraOptions = [
            # Force DNS resolution to only be the podman dnsname name server; by default podman provides a resolv.conf
            # that includes both this server and the upstream system server, causing resolutions of other pod names
            # to be inconsistent.
            "--dns=10.88.0.1"
            "--device=/dev/dri:/dev/dri"
          ];
        };



        immich-machine-learning = {
          image = "ghcr.io/immich-app/immich-machine-learning:v1.125.7";
          inherit environment;
          volumes = [
            "/zfs/photos/immich/:/usr/src/app/upload"
            "/var/lib/immich/machine-learning:/cache"
          ];
          extraOptions = [
            # Force DNS resolution to only be the podman dnsname name server; by default podman provides a resolv.conf
            # that includes both this server and the upstream system server, causing resolutions of other pod names
            # to be inconsistent.
            "--dns=10.88.0.1"
          ];

        };

        immich-redis = {
          image = "registry.hub.docker.com/library/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae";
          extraOptions = [
            "--health-cmd=redis-cli ping || exit 1"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-start-period=30s"
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
          #  extraOptions = [
          #   ''--health-cmd=pg_isready --dbname=''${DB_DATABASE_NAME} --username=''${DB_USERNAME} || exit 1; Chksum="$$(psql --dbname=''${DB_DATABASE_NAME} --username=''${DB_USERNAME} --tuples-only --no-align --command='SELECT COALESCE(SUM(checksum_failures), 0) FROM pg_stat_database')"; echo "checksum failure count is $$Chksum"; [ "$$Chksum" = '0' ] || exit 1''
          #   "--health-interval=10s"
          #   "--health-timeout=5s"
          #   "--health-start-period=30s"
          # ];
        };
      };


    # services.redis.servers.immich = {
    #   enable = true;
    #   user = "immich";
    # };

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
        proxyWebsockets = true;
      };
      extraConfig = ''
        client_max_body_size 0;
        proxy_connect_timeout 600;
        proxy_read_timeout 600;
        proxy_send_timeout 600;
      '';
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    services.vmagent = {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "immich";
            # scrape_timeout = "40s";
            static_configs = [
              {
                targets = [ "http://127.0.0.1:${builtins.toString port}" ];
              }
            ];
          }
        ];
      };
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
