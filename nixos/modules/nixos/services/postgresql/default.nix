{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "postgresql";
  category = "services";
  description = "Postgres RDMS";
  # user = "%{user kah}"; #string
  # group = "%{group kah}"; #string
  # port = 1234; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  # host = "${app}" + (if cfg.dev then "-dev" else "");
  # url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      prometheus = mkOption
        {
          type = lib.types.bool;
          description = "Enable prometheus scraping";
          default = true;
        };
      backup = mkOption
        {
          type = lib.types.bool;
          description = "Enable backups";
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

    services.postgresql = {
      enable = true;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
        superuser_map      root      postgres
        superuser_map      postgres  postgres
        # Let other names login as themselves
        superuser_map      /^(.*)$   \1
        superuser_map      root      rxresume
      '';
      authentication = ''
        #type database  DBuser  auth-method optional_ident_map
        local sameuser  all     peer        map=superuser_map
        local rxresume  root    peer
      '';
      settings = {
        max_connections = 2000;
        random_page_cost = 1.1;
        shared_buffers = "6GB";
      };
    };

    # enable backups
    services.postgresqlBackup = mkIf cfg.backup {
      enable = lib.mkForce true;
      location = "${config.mySystem.nasFolder}/backup/nixos/postgresql";
    };

    systemd.services.postgresqlBackup = {
      requires = [ "postgresql.service" ];
    };

    services.prometheus.exporters.postgres = {
      enable = true;
    };


    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };




  };
}
