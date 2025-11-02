{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  app = "searxng"; # string
  group = "977"; # string
  port = 8084; # int
  cfg = config.mySystem.services.${app};
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.services.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
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
        use_default_settings = true;
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
          default_theme = "simple";
          hotkeys = "vim";
          url_formatting = "pretty";
          infinite_scroll = true;
          query_in_title = true;
          search_on_category_select = true;
          static_use_hash = true;
          theme_args.simple_style = "dark";
        };

        # Search engine settings
        search = {
          autocomplete = "";
          autocomplete_min = 4;
          # favicon_resolver = "duckduckgo";
          ban_time_on_fail = 5;
          prefer_configured_language = true;
          default_lang = "en";
          formats = [
            "html"
            "json"
            "csv"
            "rss"
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
          method = "POST";
          public_instance = false;
          port = 8084;
          secret_key = "loljknahplz";
          default_http_headers = {
            X-Content-Type-Options = "nosniff";
            X-Download-Options = "noopen";
            X-Robots-Tag = "noindex, nofollow";
            Referrer-Policy = "no-referrer";
          };
        };

        # Search engines
        engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {

          # General
          "bing".disabled = false;

          # Files
          "bt4g".disabled = true;
          "kickass".disabled = true;
          "piratebay".disabled = true;
          "solidtorrents".disabled = true;
          "wikicommans.files".disabled = true;
          "z-library".disabled = false;
          "annas_archive".disabled = false;
          "library_genesis".disabled = false;
          # Images
          "tineye" = {
            disabled = false;
            timeout = 9;
            paging = true;
          };
          "duckduckgo images".disabled = false;
          "material icons".disabled = false;
          "artic".disable = true;
          "library of congress".disable = true;

          # Videos
          "duckduckgo videos".disable = false;

          # Social Media
          "reddit".disabled = false;
          # Other
          "goodreads".disabled = false;
          "chefkosh".disabled = true;
          "openlibrary".disabled = false;
          "imdb".disabled = false;
          "rottentomatoes".disabled = false;
          "tmdb".disabled = false;

          # IT
          "hackernews".disabled = false;
          "lobste.rs".disabled = false;

        };

        # Outgoing requests
        outgoing = {
          request_timeout = 3.0;
          max_request_timeout = 10.0;
          pool_connections = 100;
          pool_maxsize = 20;
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

        default_doi_resolver = "sci-hub.se";
        # hostname ranking
        # mix of kagi leaderboard
        # and a brave goggle
        # https://raw.githubusercontent.com/vnuxa/scribe_optimizations/refs/heads/main/brave.goggle
        hostnames = {
          remove = builtins.map (x: "(.*\\.)" + x + "$") (lib.splitString "\n" (builtins.readFile ./remove));
          high_priority = builtins.map (x: "(.*\\.)" + x + "$") (
            lib.splitString "\n" (builtins.readFile ./higher_domains)
          );
          low_priority = builtins.map (x: "(.*\\.)" + x + "$") (
            lib.splitString "\n" (builtins.readFile ./lower_domains)
          );
        };

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

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [
      {

        name = app;
        group = "media";
        url = "https://${app}.${config.mySystem.domain}";
        interval = "30s";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];

      }
    ];

  };
}
