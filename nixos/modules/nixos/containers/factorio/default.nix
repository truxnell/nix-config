{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "factorio";
  instance = "freight-forwarding";
  image = "factoriotools/factorio:stable@sha256:e2e42bb597e5785ce99996c0ee074e009c79dd44dcb5dea01f4640288d7e5290";
  user = "845"; #string
  group = "845"; #string
  port = 34203; #int
  port_rcon = 27019; #int
  cfg = config.mySystem.services.${app}.${instance};
  appFolder = "containers/${app}/${instance}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
in
{
  options.mySystem.services.${app}.${instance} =
    {
      enable = mkEnableOption "${app} - ${instance}";
      addToHomepage = mkEnableOption "Add ${app} - ${instance} to homepage" // { default = true; };
      openFirewall = mkEnableOption "Open firewall for ${app} - ${instance}" // {
        default = true;
      };
    };

  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers."${app}-${instance}" = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${persistentFolder}:/factorio:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [ (builtins.toString port) ]; # expose port
      labels = lib.myLib.mkTraefikLabels {
        name = app;
        domain = config.networking.domain;

        inherit port;
      };
    };
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ port ]; # I dont use rcon so not opening that too.
    };



    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{

      name = app;
      group = "media";
      url = "udp://${config.networking.hostName}:${builtins.toString port}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" "[RESPONSE_TIME] < 50" ];
    }];

    services.restic.backups = config.lib.mySystem.mkRestic
      {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      };

  };
}
