{ lib, config, pkgs, ... }:
with lib;
{

  # build up traefik docker labesl
  lib.mySystem.mkTraefikLabels = options: (
    let
      inherit (options) name;
      subdomain = if builtins.hasAttr "subdomain" options then options.subdomain else options.name;

      # created if port is specified
      service = if builtins.hasAttr "service" options then options.service else options.name;
      middleware = if builtins.hasAttr "middleware" options then options.middleware else "local-ip-only@file";
    in
    {
      "traefik.enable" = "true";
      "traefik.http.routers.${name}.rule" = "Host(`${options.name}.${config.mySystem.domain}`)";
      "traefik.http.routers.${name}.entrypoints" = "websecure";
      "traefik.http.routers.${name}.middlewares" = "${middleware}";
    } // lib.attrsets.optionalAttrs (builtins.hasAttr "port" options) {
      "traefik.http.routers.${name}.service" = service;
      "traefik.http.services.${service}.loadbalancer.server.port" = "${builtins.toString options.port}";
    } // lib.attrsets.optionalAttrs (builtins.hasAttr "scheme" options) {
      "traefik.http.routers.${name}.service" = service;
      "traefik.http.services.${service}.loadbalancer.server.scheme" = "${options.scheme}";
    } // lib.attrsets.optionalAttrs (builtins.hasAttr "service" options) {
      "traefik.http.routers.${name}.service" = service;
    }
  );

  # build a restic restore set for both local and remote
  lib.mySystem.mkRestic = options: (
    let
      excludePath = if builtins.hasAttr "excludePath" options then options.excludePath else [ ];
      timerConfig = {
        OnCalendar = "02:05";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
      ];
      initialize = true;
      backupPrepareCommand = ''
        # remove stale locks - this avoids some annoyance
        ${pkgs.restic}/bin/restic unlock || true
      '';
    in
    {
      # local backup
      "${options.app}-local" = mkIf config.mySystem.system.resticBackup.local.enable {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        passwordFile = config.sops.secrets."services/restic/password".path;
        exclude = options.excludePaths;
        repository = "${config.mySystem.system.resticBackup.local.location}/${options.appFolder}";
        inherit (options) user;
      };

      # remote backup
      "${options.app}-remote" = mkIf config.mySystem.system.resticBackup.remote.enable {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        environmentFile = config.sops.secrets."services/restic/env".path;
        passwordFile = config.sops.secrets."services/restic/password".path;
        repository = "${config.mySystem.system.resticBackup.remote.location}/${options.appFolder}";
        exclude = options.excludePaths;
        inherit (options) user;
      };

    }
  );

}
