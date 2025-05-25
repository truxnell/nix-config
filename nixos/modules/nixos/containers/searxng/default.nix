{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "searxng";
  image = "docker.io/searxng/searxng:2023.11.1-b5a8ddfec";
  user = "977"; #string
  group = "977"; #string
  port = 8084; #int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {

  services.searx = {
    enable = true;
    # environmentFile = config.sops.secrets.searxng_env_file.path;
    redisCreateLocally = false;
    package = pkgs.unstable.searxng;

    # Rate limiting
    # limiterSettings = {
    #   real_ip = {
    #     x_for = 1;
    #     ipv4_prefix = 32;
    #     ipv6_prefix = 56;
    #   };
    #
    #   botdetection = {
    #     ip_limit = {
    #       filter_link_local = true;
    #       link_token = true;
    #     };
    #   };
    # };


    # Searx configuration
    settings = {
      general = {
        contact_url = false;
        debug = false;
        donation_url = false;
        enable_metrics = true;
        instance_name = "Natflix search";
        privacypolicy_url = false;
      };

      ui = {
        center_alignment = true;
        default_locale = "en";
        default_theme = "simple";
        hotkeys = "vim";
        infinite_scroll = false;
        query_in_title = true;
        search_on_category_select = true;
        static_use_hash = true;
        theme_args.simple_style = "dark";
      };

      # Search engine settings
      search = {
        autocomplete = "brave";
        autocomplete_min = 2;
        favicon_resolver = "duckduckgo";
        ban_time_on_fail = 5;
        default_lang = "en";
        formats = [
          "html"
          "json"
        ];
        max_ban_time_on_fail = 120;
        safe_search = 0;
      };

      # Server configuration
      server = {
        base_url = "https://searxng.trux.dev";
        bind_address = "127.0.0.1";
        image_proxy = true;
        # limiter = true;
        limiter = false;
        method = "GET";
        public_instance = false;
        port = 8084;
        secret_key = "loljknahplz";
      };

      # Search engines
      engines = lib.mapAttrsToList (name: value: {inherit name;} // value) {
        "1x".disabled = true;
        "artic".disabled = true;
        "bing images".disabled = false;
        "bing videos".disabled = false;
        "bing".disabled = false;
        # "brave".disabled = false;
        # "brave.images".disabled = true;
        # "brave.news".disabled = true;
        # "brave.videos".disabled = true;

        "crowdview" = {
          disabled = false;
          weight = 0.5;
        };

        "curlie".disabled = true;
        "currency".disabled = true;
        "codeberg".disabled = false;
        "dailymotion".disabled = false;

        "ddg definitions" = {
          disabled = false;
          weight = 2;
        };

        "deviantart".disabled = false;
        "dictzone".disabled = true;
        "duckduckgo images".disabled = true;
        "duckduckgo videos".disabled = true;
        "duckduckgo".disabled = true;
        "flickr".disabled = true;
        "google images".disabled = false;
        "google news".disabled = true;
        "google play movies".disabled = true;
        "google videos".disabled = false;
        "github".disabled=false;
        "gitlab".disabled=false;
        "gentoo".disabled=true;
        "hoogle".disabled = true;
        "imgur".disabled = false;
        "invidious".disabled = true;
        "library of congress".disabled = false;
        "lingva".disabled = true;

        "material icons" = {
          disabled = true;
          weight = 0.2;
        };

        "mojeek".disabled = false;
        "mwmbl" = {
          disabled = false;
          weight = 0.4;
        };
        "npm".disabled=true;
        "rubygems".disabled=true;

        "odysee".disabled = true;
        "openverse".disabled = false;
        "peertube".disabled = false;
        "pinterest".disabled = true;
        "piped".disabled = true;
        "qwant images".disabled = true;
        "qwant videos".disabled = false;
        "qwant".disabled = false;
        "rumble".disabled = false;
        "reddit".disabled = false;
        "sepiasearch".disabled = false;
        "svgrepo".disabled = false;
        "unsplash".disabled = false;
        "vimeo".disabled = false;

        "wallhaven" = {
          disabled = false;
          api_key = "@WALLHAVEN_API_KEY@";
          safesearch_map = "0";
        };

        "wikibooks".disabled = false;
        "wikicommons.images".disabled = false;
        "wikidata".disabled = false;
        "wikiquote".disabled = true;
        "wikisource".disabled = true;

        "wikispecies" = {
          disabled = false;
          weight = 0.5;
        };

        "wikiversity" = {
          disabled = false;
          weight = 0.5;
        };

        "wikivoyage" = {
          disabled = false;
          weight = 0.5;
        };

        "yacy images".disabled = true;
        "yahoo".disabled = false;
        "youtube".disabled = false;
      };

      # Outgoing requests
      outgoing = {
        request_timeout = 5.0;
        max_request_timeout = 15.0;
        pool_connections = 100;
        pool_maxsize = 15;
        enable_http2 = true;
      };

      # Enabled plugins
      enabled_plugins = [
        "Basic Calculator"
        "Hash plugin"
        "Tor check plugin"
        "Open Access DOI rewrite"
        "Hostnames plugin"
        "Unit converter plugin"
        "Tracker URL remover"
      ];
    };
  };
    

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations = {
        "/" = {
          proxyPass = "http://127.0.0.1:8084";
        };

        "/api/" = {
          proxyPass = "http://127.0.0.1:8084";
          extraConfig = ''
            rewrite /api/ /search?format=json break;
          '';
        };
      };
    };
    

    mySystem.services.homepage.home = mkIf cfg.addToHomepage [
      {
        Searxng = {
          icon = "${app}.png";
          href = "https://${app}.${config.mySystem.domain}";
          ping = "https://${app}.${config.mySystem.domain}";
          description = "Private meta search engine";
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 1500" ];

    }];


  };
}
