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
  url = "${app}.${config.networking.domain}";

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
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    services.node-red = {
      enable = true;
      userDir = persistentFolder;
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.node-red.port}";
      };
    };



    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${url}";

          description = "Workflow automation";
          container = "${app}";
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
