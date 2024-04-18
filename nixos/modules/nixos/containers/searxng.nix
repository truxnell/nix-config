{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "searxng";
  image = "docker.io/searxng/searxng:2023.11.1-b5a8ddfec";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
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
      volumes = [
        "${configFile}:/etc/searxng/settings.yml:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        TZ = "${config.time.timeZone}";
        SEARXNG_BASE_URL = "https://searxng.${config.mySystem.domain}/"
        SEARXNG_URL = "https://searxng.${config.mySystem.domain}"
      };
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
      extraOptions = [
        "--read-only"
        "--tmpfs=/etc/searxng/"
      ];
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Searxng = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";
          ping = "https://${app}.${config.mySystem.domain}";
          description = "Private Search Engine";
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "services";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

  };
}
