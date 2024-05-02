{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "plex";
  image = "ghcr.io/onedr0p/plex:1.40.1.8227-c0dd5a73e@sha256:a60bc6352543b4453b117a8f2b89549e458f3ed8960206d2f3501756b6beb519";
  user = "568"; #string
  group = "568"; #string
  port = 32400; #int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";

  ## persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      openFirewall = mkEnableOption "Open firewall for ${app}" // {
        default = true;
      };
    };

  config = mkIf cfg.enable {

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = {
      directories = [{ directory = appFolder; user = user; group = group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${appFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/data:rw"
        "${config.mySystem.nasFolder}/backup/kubernetes/apps/plex:/config/backup:rw"
        "/dev/dri:/dev/dri" # for hardware transcoding
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment = {
        PLEX_ADVERTISE_URL = "https://10.8.20.42:32400,https://${app}.${config.mySystem.domain}:443"; # TODO var ip
      };
      ports = [ "${builtins.toString port}:${builtins.toString port}" ]; # expose port
    };
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ port ];
      allowedUDPPorts = [ port ];
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
        Plex = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Media streaming service";
          container = "${app}";
          widget = {
            type = "tautulli";
            url = "https://tautulli.${config.mySystem.domain}";
            key = "{{HOMEPAGE_VAR_TAUTULLI__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}/web/";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        # excludePaths = [ "Backups" ];
        paths = [ appFolder ];
        inherit appFolder;
      };

  };
}
