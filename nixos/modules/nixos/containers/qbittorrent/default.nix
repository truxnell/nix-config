{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "qbittorrent";
  user = "kah"; #string
  group = "kah"; #string
  port = 8080; #int
  qbit_port = 32189;
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  xseedShell = pkgs.writeScriptBin "xseed.sh" # scrit to call cross-seed upon torrent finish
  ''
    #!/bin/bash
    # qbit command: /scripts/xseed.sh "%F" "%R"
    chmod 755 -R $2
    /usr/bin/curl -X POST --data-urlencode "path=$1" https://cross-seed.trux.dev/api/webhook
  '';

in
{

  imports = [
    ./qbtools.nix
  ];

  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      qbtools = mkEnableOption "qbtools" // { default = true; };
      openFirewall = mkEnableOption "Open firewall for ${app}" // {
        default = true;
      };

    };

  config = mkIf cfg.enable {
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${appFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} =
      let
        image = "ghcr.io/onedr0p/qbittorrent:4.6.5@sha256:c019af23966ebafcaf1713d4553bc043246858b711a7d57d8bee358a89990a3e";
      in
      {
        image = "${image}";
        user = "568:568";
        environment = {
          QBITTORRENT__BT_PORT = builtins.toString qbit_port;
        };
        ports = [ "${builtins.toString qbit_port}:${builtins.toString qbit_port}" ];
        volumes = [
          "${appFolder}:/config:rw"
          "${xseedShell}/bin/xseed.sh:/scripts/xseed.sh:Z"
          "/tank//natflix/downloads/qbittorrent:/tank/natflix/downloads/qbittorrent:rw"
          "/mnt/cache:/cache"
          "/etc/localtime:/etc/localtime:ro"
        ];
      };

 

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };


    # gotta open up that firewall
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ qbit_port ];
      allowedUDPPorts = [ qbit_port ];
    };


    mySystem.services.homepage.media = mkIf cfg.addToHomepage [
      {
        Qbittorrent = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";

          description = "Torrent Downloader";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
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
