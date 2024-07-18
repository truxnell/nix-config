{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "factorio";
  instance = "freight-forwarding";
  image = "factoriotools/factorio:stable@sha256:69e57b2370b3d064891cd306b29a6ae2a7290be1dc80b8ecca44e624901ae429";
  user = "845"; #string
  group = "845"; #string
  port = 34203; #int
  port_rcon = 27019; #int
  cfg = config.mySystem.services.${app}.${instance};
  appFolder = "/var/lib/${app}/${instance}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
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
      "d ${appFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];
    # make user for container
    users = {
      users.${app} = {
        name = app;
        uid = lib.strings.toInt user;
        group = app;
        isSystemUser = true;
      };
      groups.${app} = {
        gid = lib.strings.toInt group;
      };
    };
    # add user to group to view files/storage
    users.users.truxnell.extraGroups = [ "${app}" ];

    sops.secrets."services/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = app;
      group = app;
      restartUnits = [ "podman-${app}-${instance}.service" ];
    };


    virtualisation.oci-containers.containers."${app}-${instance}" = {
      image = "${image}";
      user = "${user}:${group}";
      volumes = [
        "${appFolder}:/factorio:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environment =
        {
          UPDATE_MODS_ON_START = "false";
          PORT = "34203";
          RCON_PORT = "27019";
        };
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      ports = [ "${builtins.toString port}:${builtins.toString port}/UDP" ]; # expose port
    };
    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ port ]; # I dont use rcon so not opening that too.
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
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
