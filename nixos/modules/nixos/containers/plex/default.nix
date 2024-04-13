{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "plex";
  image = "ghcr.io/onedr0p/plex:1.40.1.8227-c0dd5a73e@sha256:c8d74539a40530fa9770c6d67f37aef8f3a7b3f30ee353c2cb5685b84ed5b04c";
  user = "568"; #string
  group = "568"; #string
  port = 32400; #int
  cfg = config.mySystem.services.${app};
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";
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
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "${config.mySystem.nasFolder}/backup/kubernetes/apps/plex:/config/backup:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ (builtins.toString port) ]; # expose port
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };


    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Plex = {
          icon = "${app}.png";
          href = "https://${app}.${config.mySystem.domain}";
          ping = "https://${app}.${config.mySystem.domain}";
          description = "Media streaming service";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
            key = "{{HOMEPAGE_VAR_LIDARR__API_KEY}}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "media";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

  };
}
