{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "searxng";
  image = "ghcr.io/benbusby/whoogle-search:0.8.4@sha256:93977c3aec8a039df94745a6e960d1b590a897e451b874c90ce484fbdbc3630f";
  user = "568"; #string
  group = "568"; #string
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
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };

    mySystem.services.homepage.home-services = mkIf cfg.addToHomepage [
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
