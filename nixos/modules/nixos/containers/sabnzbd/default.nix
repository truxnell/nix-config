{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "sabnzbd";
  image = "ghcr.io/onedr0p/sabnzbd:4.2.3@sha256:8943148a1ac5d6cc91d2cc2aa0cae4f0ab3af49fb00ca2d599fbf0344798bc37";
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
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        SABNZBD__HOST_WHITELIST_ENTRIES = "sabnzbd, sabnzbd.trux.dev";
      };
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };


    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        Sabnzbd = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";
          description = "Usenet Downloader";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
            key = "{{HOMEPAGE_VAR_SABNZBD__API_KEY}}";
          };
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
