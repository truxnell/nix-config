{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "tautulli";
  image = "ghcr.io/onedr0p/tautulli:2.13.4@sha256:633a57b2f8634feb67811064ec3fa52f40a70641be927fdfda6f5d91ebbd5d73";
  user = "568"; #string
  group = "568"; #string
  port = 8181; #int
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
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "${config.mySystem.nasFolder}/backup/kubernetes/apps/tautulli:/config/backup:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = lib.myLib.mkTraefikLabels {
        name = app;
        inherit (config.networking) domain;

        inherit port;
      };
    };

    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        Tautulli = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Plex Monitoring & Stats";
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

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        excludePaths = [ "Backups" ];
        paths = [ appFolder ];
        inherit appFolder;
      };


  };
}
