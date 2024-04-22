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
  port = 8080; #int
  cfg = config.mySystem.services.${app};
  appFolder = "containers/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
  configNix = { use_default_settings = { engines = { keep_only = [ "arch linux wiki" "google" "google images" "google news" "google videos" "google scholar" "google play apps" "duckduckgo" "brave" "startpage" "gitlab" "github" "codeberg" "sourcehut" "bitbucket" "apple app store" "wikipedia" "currency" "docker hub" "ddg definitions" "duckduckgo images" "bandcamp" "deviantart" "tineye" "apple maps" "fdroid" "flickr" "free software directory" "z-library" "lobste.rs" "azlyrics" "openstreetmap" "npm" "pypi" "lib.rs" "nyaa" "reddit" "sepiasearch" "soundcloud" "stackoverflow" "askubuntu" "superuser" "searchcode code" "unsplash" "youtube" "wolframalpha" "mojeek" ]; }; }; engines = [{ name = "brave"; disabled = false; } { name = "startpage"; disabled = false; } { name = "apple app store"; disabled = false; } { name = "ddg definitions"; disabled = false; } { name = "tineye"; disabled = false; } { name = "apple maps"; disabled = false; } { name = "duckduckgo images"; disabled = false; } { name = "fdroid"; disabled = false; } { name = "free software directory"; disabled = false; } { name = "bitbucket"; disabled = false; } { name = "gitlab"; disabled = false; } { name = "codeberg"; disabled = false; } { name = "google play apps"; disabled = false; } { name = "lobste.rs"; disabled = false; } { name = "azlyrics"; disabled = false; } { name = "npm"; disabled = false; } { name = "nyaa"; disabled = false; categories = "videos"; } { name = "searchcode code"; disabled = false; } { name = "mojeek"; disabled = false; } { name = "lib.rs"; disabled = false; } { name = "sourcehut"; disabled = false; }]; general = { instance_name = "NatFlix Search"; enable_metrics = false; }; brand = { new_issue_url = ""; docs_url = ""; public_instances = ""; wiki_url = ""; issue_url = ""; }; search = { safe_search = 0; autocomplete = "duckduckgo"; autocomplete_min = 2; default_lang = "en"; max_page = 0; }; server = { base_url = "https://searxng.\${EXTERNAL_DOMAIN}/"; image_proxy = true; http_protocol_version = "1.1"; method = "GET"; }; ui = { static_use_hash = true; infinite_scroll = true; default_theme = "simple"; theme_args = { simple_style = "dark"; }; }; enabled_plugins = [ "Hash plugin" "Search on category select" "Self Information" "Tracker URL remover" "Open Access DOI rewrite" "Vim-like hotkeys" ]; };
  configFile = builtins.toFile "config.yaml" (builtins.toJSON configNix);
in
{
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${configFile}:/config/config.yaml:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "${config.time.timeZone}";
        SEARXNG_BASE_URL = "https://searxng.${config.mySystem.domain}/";
        SEARXNG_URL = "https://searxng.${config.mySystem.domain}";
      };
      labels = lib.myLib.mkTraefikLabels {
        name = app;
        domain = config.networking.domain;

        inherit port;
      };
      extraOptions = [
        "--read-only"
        "--tmpfs=/etc/searxng/"
        "--cap-add=CHOWN"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
        "--cap-add=DAC_OVERRIDE"
      ];

    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Tautulli = {
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
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];

    }];


  };
}
