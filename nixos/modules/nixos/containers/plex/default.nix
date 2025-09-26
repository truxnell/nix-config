{ lib
, config
, ...
}:
with lib;
let
  app = "plex";
  image = "ghcr.io/onedr0p/plex:1.40.1.8227-c0dd5a73e@sha256:a60bc6352543b4453b117a8f2b89549e458f3ed8960206d2f3501756b6beb519";
  user = "kah"; #string
  group = "kah"; #string
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      volumes = [
        "${appFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/data:rw"
        "/zfs/backup/kubernetes/apps/plex:/config/backup:rw" # TODO fix backup path with var.
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
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };




    mySystem.services.gatus.monitors = [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}/web/";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 1500" ];
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
