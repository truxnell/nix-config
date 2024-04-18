{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "factorio";
  atom = "freight-forwarding";
  image = "factoriotools/factorio:stable@sha256:e2e42bb597e5785ce99996c0ee074e009c79dd44dcb5dea01f4640288d7e5290";
  user = "568"; #string
  group = "568"; #string
  port = 34203; #int
  port_rcon = 27019; #int
  cfg = config.mySystem.services.${app}.${atom};
  appFolder = "containers/${app}/${atom}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
in
in
{
  options.mySystem.services.${app}.${atom} =
    {
      enable = mkEnableOption "${app} - ${atom}";
      addToHomepage = mkEnableOption "Add ${app} - ${atom} to homepage" // { default = true; };
      openFirewall = mkEnableOption "Open firewall for ${app} - ${atom}" // {
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

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        excludePaths = [ "Backups" ];
        paths = [ appFolder ];
        inherit appFolder;
      };

  };
}
