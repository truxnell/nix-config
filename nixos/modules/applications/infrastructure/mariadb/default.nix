{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "mariadb";
  category = "services";
  description = "mysql-compatiable database";
  # image = "";#string
  inherit (config.services.mysql) group; # string
  # port = ; #int
  # appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
  };

  config = mkIf cfg.enable {

    ## Secrets
    # sops.secrets."${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "${app}.service" ];
    # };

    users.users.truxnell.extraGroups = [ group ];

    ## service
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

  };
}
