{
  lib,
  config,
  ...
}:
with lib;
let
  app = "sabnzbd";
  image = "ghcr.io/home-operations/sabnzbd:4.5.5";
  user = "kah"; # string
  group = "kah"; # string
  port = 8080; # int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.services.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${appFolder} 0750 ${user} ${group} -" # The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      environment = {
        SABNZBD__HOST_WHITELIST_ENTRIES = "sabnzbd, sabnzbd.trux.dev";
      };
      volumes = [
        "${appFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix/downloads/sabnzbd/:/tank/natflix/downloads/sabnzbd/:rw"
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              inherit user;
              inherit group;
              mode = "750";
            }
          ];
        };

    mySystem.services.gatus.monitors = [
      {

        name = app;
        group = "media";
        url = "https://${app}.${config.mySystem.domain}";

        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    services.restic.backups = config.lib.mySystem.mkRestic {
      inherit app user;
      excludePaths = [ "Backups" ];
      paths = [ appFolder ];
      inherit appFolder;
    };

  };
}
