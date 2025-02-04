{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "open-webui";
  category = "services";
  description = "front end for LLM and stable-diffusion";
  image = "ghcr.io/open-webui/open-webui:main";
  user = "kah"; #string
  group = "kah"; #string
  port = 11111; #int
  appFolder = "/var/lib/private/${app}";
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
      group = group;
      mode = "0666";
      restartUnits = [ "${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];


    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };


    ## service
    services.open-webui= {
      enable = true;
      package=pkgs.unstable.open-webui;
      # openFirewall=true;
      inherit port;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";

        DEFAULT_LOCALE = "en";

        ENABLE_ADMIN_CHAT_ACCESS = "True";
        ENABLE_ADMIN_EXPORT = "True";
        SHOW_ADMIN_DETAILS = "True";
        ADMIN_EMAIL = "admin@${config.networking.hostName}";

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
        CONTENT_EXTRACTION_ENGINE="tika";
        RAG_WEB_SEARCH_ENGINE="searxng";

        ENABLE_SEARCH_QUERY_GENERATION = "True";
        SEARXNG_QUERY_URL="https://searxng.${config.networking.domain}/search";

        ENABLE_TAGS_GENERATION = "True";

        ENABLE_IMAGE_GENERATION = "True";

        YOUTUBE_LOADER_LANGUAGE = "en";

        ENABLE_MESSAGE_RATING = "True";

        ENABLE_COMMUNITY_SHARING = "True";

        ENABLE_RAG_WEB_LOADER_SSL_VERIFICATION = "True";
        WEBUI_SESSION_COOKIE_SAME_SITE = "strict";
        WEBUI_SESSION_COOKIE_SECURE = "True";
        WEBUI_AUTH = "False";

        ENABLE_OLLAMA_API = "True";
        ENABLE_OPENAI_API = "True";
        TIKA_SERVER_URL="http://127.0.0.1:33001";

      };
      environmentFile = config.sops.secrets."${category}/${app}/env".path;
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
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.open-webui.port}";
        proxyWebsockets = true;
        extraConfig = ''
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
