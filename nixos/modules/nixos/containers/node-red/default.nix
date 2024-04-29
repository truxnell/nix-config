{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.node-red;
  app = "node-red";
  persistentFolder = "${config.mySystem.persistentFolder}/apps/${app}";
  user = config.services.node-red.user;
  group = config.services.node-red.group;

in
{
  options.mySystem.services.node-red.enable = mkEnableOption "node-red";

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
        rule = "Host(`${app}-d.${config.mySystem.domain}`)";
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


  };
}
