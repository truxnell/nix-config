{
  lib,
  config,
  ...
}:
with lib;
let
  app = "home-assistant";
  image = "ghcr.io/home-operations/home-assistant:2025.12.2";
  user = "kah"; # string
  group = "kah"; # string
  port = 8123; # int
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

    sops.secrets."services/${app}/env" = {

      # configure secret for forwarding rules
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
      restartUnits = [ "podman-${app}.service" ];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      environment = {
        HASS_IP = "10.8.20.42";
      };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "${appFolder}:/config:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        proxyWebsockets = true;
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              user = "kah";
              group = "kah";
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
      inherit app;
      user = builtins.toString user;
      excludePaths = [ "Backups" ];
      paths = [ appFolder ];
      inherit appFolder;
    };
  };
}
