{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.services.mcp-grafana;
  app = "mcp-grafana";
  category = "services";
  description = "MCP server for Grafana";
  image = "docker.io/grafana/mcp-grafana";
  user = "kah";
  group = "kah";
  port = 9092; # Default port for SSE/HTTP transport
  appFolder = "/var/lib/${app}";
  
  # Get Loki URL from Loki configuration
  lokiUrl = "https://loki.${config.networking.domain}";
  
  # Get Grafana URL
  grafanaUrl = "https://grafana.${config.networking.domain}";
in
{
  options.mySystem.services.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = false; # MCP server doesn't have a web UI
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = false; # MCP server doesn't expose HTTP endpoints
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = false; # MCP server is stateless
    };
  };

  config = mkIf cfg.enable {
    ## Secrets
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
      restartUnits = [ "podman-${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    #   "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              inherit user;
              inherit group;
              mode = "750";
            }
          ];
        };

    ## Container Configuration
    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image;
      user = "568";
      group = "568";
      env = {
        GRAFANA_URL = grafanaUrl;
        # GRAFANA_SERVICE_ACCOUNT_TOKEN will come from secrets file
        # LOKI_URL is optional but can be used if needed
        LOKI_URL = lokiUrl;
      };
      envFiles = [ config.sops.secrets."${category}/${app}/env".path ];
      # Use SSE transport for systemd-managed service
      # MCP clients can connect via SSE or use stdio by spawning the container directly
      cmd = [ "-t" "sse" "-address" ":${builtins.toString port}" ];
      volumes = [ ];
      ports = [ "${builtins.toString port}:${builtins.toString port}" ];
    };

    ### backups
    # warnings = [
    #   (mkIf (
    #     !cfg.backup && config.mySystem.purpose != "Development"
    #   ) "WARNING: Backups for ${app} are disabled!")
    # ];

    # services.restic.backups = mkIf cfg.backup (
    #   config.lib.mySystem.mkRestic {
    #     inherit app user;
    #     paths = [ appFolder ];
    #     inherit appFolder;
    #   }
    # );
  };
}

