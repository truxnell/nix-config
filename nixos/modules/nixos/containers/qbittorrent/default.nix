{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "qbittorrent";
  image = "ghcr.io/onedr0p/qbittorrent:4.6.3@sha256:f2895e632fe66299d8ccc68265cc11aea92a232b7d0844de9961864b3e504026";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
  cfg = config.mySystem.services.${app};
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";
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
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        QBITTORRENT__BT_PORT = "32189";
      };
      volumes = [
        "${persistentFolder}:/config:rw"
        "/mnt/nas/natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Qbittorrent = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Torrent Downloader";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.networking.domain}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "arr";
      url = "https://${app}.${config.networking.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }];

  };
}
