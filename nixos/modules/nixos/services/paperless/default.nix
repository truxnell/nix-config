{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "paperless";
  category = "services";
  description = "document managment";
  # image = "";
  user = "paperless"; #string
  group = "paperless"; #string
  inherit (config.services.paperless) port;#int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  tikaPort = "33001";
  gotenbergPort = "33002";
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
    sops.secrets."${category}/${app}/passwordFile" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # ensure postgresql setup
    services.postgresql = {
      ensureDatabases = [ app ];
      ensureUsers = [{
        name = app;
        ensureDBOwnership = true;
      }];
    };

    # systemd.services.podman-rxresume={
    #   after = [ "postgresql.service" ];
    #   requires = [ "postgresql.service" ];
    # };


    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }
        { directory = "/var/lib/redis-paperless"; }];
    };


    ## service
    services.paperless = {
      enable = true;
      dataDir = "/var/lib/paperless";
      mediaDir = "/zfs/documents/paperless/media";
      consumptionDir = "/zfs/documents/paperless/inbound";
      consumptionDirIsPublic = true;
      port = 8000;
      address = "localhost";
      passwordFile = config.sops.secrets."${category}/${app}/passwordFile".path;
      settings = {
        PAPERLESS_OCR_LANGUAGE = "eng";
        PAPERLESS_CONSUMER_POLLING = "60";
        PAPERLESS_CONSUMER_RECURSIVE = "true";
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = "true";
        # PAPERLESS_DBENGINE = "postgresql";
        # PAPERLESS_DBHOST = "/run/postgresql";
        HOME = "/tmp"; # Prevent GNUPG home dir error
        PAPERLESS_TIKA_ENABLED = true;
        PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:${tikaPort}";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:${gotenbergPort}";
      };
    };
    # for word/etc conversions
    virtualisation.oci-containers.containers = {
      gotenberg = {
        user = "gotenberg:gotenberg";
        image = "gotenberg/gotenberg:8.14.1";
        cmd = [ "gotenberg" "--chromium-disable-javascript=true" "--chromium-allow-list=file:///tmp/.*" ];
        ports = [
          "127.0.0.1:${gotenbergPort}:3000"
        ];
      };
      tika = {
        image = "apache/tika:2.5.0";
        ports = [
          "127.0.0.1:${tikaPort}:9998"
        ];
      };
    };



    services.prometheus.exporters.redis = {
      enable = true;
      port = 10394;
    };

    services.vmagent = {
      enable = true;
      remoteWrite.url = "http://shodan:8428/api/v1/write";
      extraArgs = lib.mkForce [ "-remoteWrite.label=instance=${config.networking.hostName}" ];
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "redis";
            # scrape_timeout = "40s";
            static_configs = [
              {
                targets = [ "http://localhost:10394" ];

              }
            ];
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
          widget = {
            type = "paperlessngx";
            url = "https://${url}";
            key = "{{HOMEPAGE_VAR_PAPERLESS_API_KEY}}";
          };
        };
      }
    ];

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}/api";
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
        extraConfig = ''
          resolver 10.88.0.1;
          client_max_body_size 256m;
        '';
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
      # (mkIf (!config.services.postgresql.enable)
      #   "WARNING: Postgres is not enabled on host for ${app}!")
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
