{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "qbittorrent";
  image = "ghcr.io/onedr0p/qbittorrent:4.6.4@sha256:cb8a7df4e63bf410834af7846b6d5eee4f10748d03819ee7218015c5b0332a29";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
  qbit_port = 32189;
  cfg = config.mySystem.services.${app};
  persistentFolder = "${config.mySystem.persistentFolder}/containers/${app}";
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
      "d ${persistentFolder}/nixos 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      environment = {
        QBITTORRENT__BT_PORT = builtins.toString qbit_port;
      };
      ports = [ "${builtins.toString qbit_port}:${builtins.toString qbit_port}" ];
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}/natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };
    # gotta open up that firewall
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ qbit_port ];
      allowedUDPPorts = [ qbit_port ];
    };


    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Qbittorrent = {
          icon = "${app}.png";
          href = "https://${app}.${config.mySystem.domain}";
          ping = "https://${app}.${config.mySystem.domain}";
          description = "Torrent Downloader";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
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

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        excludePaths = [ "Backups" ];
        paths = [ persistentFolder ];
      };


  };
}
