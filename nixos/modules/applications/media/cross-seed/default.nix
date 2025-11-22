{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "cross-seed";
  category = "services";
  description = "xseed";
  image = "ghcr.io/cross-seed/cross-seed:6.13.6";
  user = "568"; # string
  group = "568"; # string
  port = 2468; # int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };

  };

  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."${category}/${app}/config.js" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

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

    ## service
    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      cmd = [ "daemon" ];
      volumes = [
        "${appFolder}:/config:rw"
        "/tank/natflix/downloads/:/tank/natflix/downloads/:rw"
        "/var/lib/qbittorrent/qBittorrent/BT_backup:/qbit-torrents:ro"
        ''${config.sops.secrets."${category}/${app}/config.js".path}:/config/config.js:ro''
        "/etc/localtime:/etc/localtime:ro"
      ];

    };
    systemd.services.${app} = {
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
      };
      requires = [
        "qbittorrent.service"
        "cross-seed.service"
      ];
      after = [
        "qbittorrent.service"
        "cross-seed.service"
      ];

    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };

    services.restic.backups = config.lib.mySystem.mkRestic {
      inherit app user;
      excludePaths = [ "Backups" ];
      paths = [ appFolder ];
      inherit appFolder;
    };

  };
}
