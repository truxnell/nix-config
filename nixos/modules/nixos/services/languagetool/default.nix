{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${x}.${y};
  app = "%{app}";
  category = "%{cat}"
  description ="%{description}
  image = "%{image}";
  user = "%{user kah}"; #string
  group = "%{group kah}"; #string
  port = %{port}; #int
  appFolder = "${category}/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
  url = "${app}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;
        };
    };

  config = mkIf cfg.enable {

    # sops.secrets."/${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "${app}.service" ];
    # };

    users.users.truxnell.extraGroups = [ group ];


    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder}/ 0750 ${user} ${group} -"
    ];

    ## service

    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";
          description = description;
        };
      }
    ];

    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${app}.${config.mySystem.domain}";
        interval = "1m";
        conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
      }
    ];

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

  };
}
