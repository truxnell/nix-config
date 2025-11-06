{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "open-webui";
  category = "services";
  description = "front end for LLM and stable-diffusion";
  image = "ghcr.io/open-webui/open-webui:latest@sha256:53a4d2fc8c7a7cc620cd18e6fe416ed9940f2db87fddf837e3aa55111bec6995";
  user = "kah"; # string
  group = "kah"; # string
  port = 11111; # int
  appFolder = "/var/lib/private/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
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
      mode = "0666";
      restartUnits = [ "podman-${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              inherit user;
              inherit group;
              mode = "750";
            }
          ];
        };

    ## service
    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";

        DEFAULT_LOCALE = "en";

        ENABLE_ADMIN_CHAT_ACCESS = "True";
        ENABLE_ADMIN_EXPORT = "True";
        SHOW_ADMIN_DETAILS = "True";
        ADMIN_EMAIL = "admin@${config.networking.hostName}";
        WEBUI_URL = "https://${url}";

        USER_PERMISSIONS_WORKSPACE_MODELS_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_KNOWLEDGE_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_PROMPTS_ACCESS = "True";
        USER_PERMISSIONS_WORKSPACE_TOOLS_ACCESS = "True";

        USER_PERMISSIONS_CHAT_TEMPORARY = "True";
        USER_PERMISSIONS_CHAT_FILE_UPLOAD = "True";
        USER_PERMISSIONS_CHAT_EDIT = "True";
        USER_PERMISSIONS_CHAT_DELETE = "True";

        ENABLE_CHANNELS = "True";

        ENABLE_REALTIME_CHAT_SAVE = "True";

        ENABLE_AUTOCOMPLETE_GENERATION = "True";
        AUTOCOMPLETE_GENERATION_INPUT_MAX_LENGTH = "-1";

        ENABLE_RAG_WEB_SEARCH = "True";
        CONTENT_EXTRACTION_ENGINE = "tika";
        RAG_WEB_SEARCH_ENGINE = "searxng";

        ENABLE_SEARCH_QUERY_GENERATION = "True";
        SEARXNG_QUERY_URL = "https://searxng.${config.networking.domain}/search";

        ENABLE_TAGS_GENERATION = "True";

        ENABLE_IMAGE_GENERATION = "True";
        IMAGE_GENERATION_ENGINE = "automatic1111";
        IMAGE_GENERATION_MODEL = "";
        AUTOMATIC1111_BASE_URL = "http://citadel:7860";
        AUTOMATIC1111_CFG_SCALE = "4.5";
        AUTOMATIC1111_SAMPLER = "DPM++ 2M";
        AUTOMATIC1111_SCHEDULER = "Karras";

        YOUTUBE_LOADER_LANGUAGE = "en";

        ENABLE_MESSAGE_RATING = "True";

        ENABLE_COMMUNITY_SHARING = "True";

        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "True";
        WEBUI_SESSION_COOKIE_SAME_SITE = "strict";
        WEBUI_SESSION_COOKIE_SECURE = "True";
        WEBUI_AUTH = "False";

        ENABLE_OLLAMA_API = "True";
        ENABLE_OPENAI_API = "True";
        TIKA_SERVER_URL = "http://127.0.0.1:33001";
      };
      environmentFiles = [ config.sops.secrets."${category}/${app}/env".path ];

      volumes = [
        "/var/lib/open-webui:/app/backend/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString config.services.open-webui.port}";
        proxyWebsockets = true;
        extraConfig = ''
          client_max_body_size 256m;
          resolver 10.88.0.1;
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
      (mkIf (
        !cfg.backup && config.mySystem.purpose != "Development"
      ) "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };

  };
}
