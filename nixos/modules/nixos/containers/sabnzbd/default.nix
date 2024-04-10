{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "sabnzbd";
  image = "ghcr.io/onedr0p/sabnzbd:4.2.3@sha256:bb20d3940ff32c672111ad7169ce4156f1c4c08bb653241f1b14f6d00f93b3cc";
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
        SABNZBD__HOST_WHITELIST_ENTRIES = "sabnzbd, sabnzbd.trux.dev";
      };
      volumes = [
        "${persistentFolder}:/config:rw"
        "${config.mySystem.nasFolder}natflix:/media:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
    };

    mySystem.services.homepage.media-services = mkIf cfg.addToHomepage [
      {
        Sabnzbd = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Usenet Downloader";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.networking.domain}";
            key = "{{HOMEPAGE_VAR_SABNZBD__API_KEY}}";
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
