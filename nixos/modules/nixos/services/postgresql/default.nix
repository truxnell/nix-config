{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "postgresql";
  category = "services";
  description = "Postgres RDMS";
  appFolder = config.services.postgresql.dataDir;
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    backup = mkOption {
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              user = "postgres";
              group = "postgres";
              mode = "750";
            }
          ];
        };

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
        max_wal_senders = 3;
        wal_level = "replica";
      };
    };

    # enable backups
    systemd.services.postgresql-backup = {
      description = "PostgreSQL base backup";
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        Group = "postgres";
        ExecStart = pkgs.writeScript "pg-backup" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail

          # Create compressed backup
          ${pkgs.postgresql}/bin/pg_basebackup \
            -D ${config.mySystem.nasFolder}/backups/postgres/basebackup-${config.networking.hostName}-$(date +%Y%m%d-%H%M%S) \
            -Ft -z -P -v

        '';
      };
    };

    systemd.timers.postgresql-backup = {
      description = "Daily PostgreSQL backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
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
