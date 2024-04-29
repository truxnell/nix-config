{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.node-red;
  app = "node-red";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
  appFolder = "apps/${app}";
  inherit (config.services.node-red) user;
  inherit (config.services.node-red) group;
  url = "code-${config.networking.hostName}.${config.networking.domain}";

in
{
  options.mySystem.services.node-red =
    {
      enable = mkEnableOption "node-red";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    services.node-red = {
      enable = true;
      userDir = persistentFolder;
    };

    mySystem.services.traefik.routers = [{
      http.routers.${app} = {
        rule = "Host(`${app}.${config.mySystem.domain}`)";
        entrypoints = "websecure";
        middlewares = "local-ip-only@file";
        service = "${app}";
      };
      http.services.${app} = {
        loadBalancer = {
          servers = [{
            url = "http://localhost:1880";
          }];
        };
      };

    }];

    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        code-shodan = {
          icon = "${app}.svg";
          href = "https://${url}";

          description = "Music management";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${url}";
            key = "{{HOMEPAGE_VAR_LIDARR__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "media";
      url = "https://${url}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app;
        user = builtins.toString user;
        excludePaths = [ "Backups" ];
        paths = [ appFolder ];
        inherit appFolder;
      };




  };
}
