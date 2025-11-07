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



        #type database  DBuser     auth-method optional_ident_map
        local all       postgres   peer        map=superuser_map
        local sameuser  all        peer        map=superuser_map
        local rxresume  root       peer
      '';
      settings = {
        random_page_cost = 1.1;
        shared_buffers = "6GB";
      };
    };

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app;
        user = "postgres";
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

    systemd.services.restic-backups-postgresql-local.serviceConfig.ExecStart = mkForce (
      pkgs.writeShellScript "restic-backups-postgresql-local-ExecStart" ''
        set -o pipefail
        ${config.services.postgresql.package}/bin/pg_dumpall -U postgres \
          | ${pkgs.restic}/bin/restic backup --stdin --stdin-filename postgres.sql
      ''
    );

  };
}
