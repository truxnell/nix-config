{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "cross-seed";
  image = "ghcr.io/onedr0p/sabnzbd:4.3.2@sha256:8e70a877c77805dfe93ce30a8da3362fbddf221ef806951d4e4634bb80dc87b5";
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
