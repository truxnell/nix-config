{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "whoogle";
  image = "ghcr.io/benbusby/whoogle-search:0.8.4@sha256:93977c3aec8a039df94745a6e960d1b590a897e451b874c90ce484fbdbc3630f";
  user = "927"; #string
  group = "927"; #string
  port = 5000; #int
  cfg = config.mySystem.services.${app};
  appFolder = "containers/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
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
      ports = [ (builtins.toString port) ]; # expose port
      environment = {
        TZ = "${config.time.timeZone}";
        WHOOGLE_ALT_TW = "nitter.${config.networking.domain}";
        WHOOGLE_ALT_YT = "invidious.${config.networking.domain}";
        WHOOGLE_ALT_IG = "imginn.com";
        WHOOGLE_ALT_RD = "redlib.${config.networking.domain}";
        WHOOGLE_ALT_MD = "scribe.${config.networking.domain}";
        WHOOGLE_ALT_TL = "";
        WHOOGLE_ALT_IMG = "bibliogram.art";
        WHOOGLE_ALT_IMDB = "";
        WHOOGLE_ALT_WIKI = "";
        WHOOGLE_ALT_QUORA = "";
        WHOOGLE_CONFIG_ALTS = "1";
        WHOOGLE_CONFIG_THEME = "system";
        WHOOGLE_CONFIG_URL = "https://search.${config.networking.domain}";
        WHOOGLE_CONFIG_GET_ONLY = "1";
        WHOOGLE_CONFIG_COUNTRY = "AU";
        WHOOGLE_CONFIG_VIEW_IMAGE = "1";
        WHOOGLE_CONFIG_DISABLE = "1";
      };

      labels = lib.myLib.mkTraefikLabels {
        name = app;
        domain = config.networking.domain;

        inherit port;
      };
    };

    mySystem.services.homepage.home = mkIf cfg.addToHomepage [
      {
        Whoogle = {
          icon = "whooglesearch.png";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Google frontend";
          container = "${app}";
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];


  };
}
