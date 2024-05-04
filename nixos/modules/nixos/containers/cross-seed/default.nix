{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "cross-seed";
  image = "ghcr.io/onedr0p/sabnzbd:4.3.1@sha256:10aa04902725e2fb8325b71fc6bbdf3399e63d6520028c2571220d54fd928aee";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  configFile = builtins.toFile "config.js" (builtins.toJSON configVar);

in
{
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
    };

  config = mkIf cfg.enable {
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${appFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      cmd = [ "daemon" ];
      volumes = [
        "${appFolder}:/config:rw"
        "${configFile}:/config/config.yaml:ro"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

  };
}
