{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "tautulli";
  image = "ghcr.io/onedr0p/tautulli:2.14.6@sha256:267de8bb88e82d9814e9374b0cc847d771cb83a4c5296e4bc083ab6fbac60a22";
  user = "kah"; #string
  group = "kah"; #string
  port = 8181; #int
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
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${appFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      volumes = [
        "${appFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "${config.mySystem.nasFolder}/backup/nixos/manual/tautulli:/config/backup:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
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
