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
        #
        ${pkgs.restic}/bin/restic unlock --remove-all || true
      '';
    in
    {
      # local backup
      "${options.app}-local" = mkIf config.mySystem.system.resticBackup.local.enable {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        passwordFile = config.sops.secrets."services/restic/password".path;
        exclude = excludePath;
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
        exclude = excludePath;
        inherit (options) user;
      };

    }
  );

  # Will be v. useful when i grok
  # https://github.com/ahbk/my-nixos/blob/5fe1521b11422c66fd823b442393b3b044a5a5b8/lib.nix#L5
  # pick a list of attributes from an attrSet
  lib.mySystem.pick = attrNames: attrSet: lib.filterAttrs (name: value: lib.elem name attrNames) attrSet;

  # create an env-file (package) that can be sourced to set environment variables
  lib.mySystem.mkEnv = name: value: pkgs.writeText "${name}-env" (concatStringsSep "\n" (mapAttrsToList (n: v: "${n}=${v}") value));

  # loop over an attrSet and merge the attrSets returned from f into one (latter override the former in case of conflict)
  lib.mySystem.mergeAttrs = f: attrs: foldlAttrs (acc: name: value: (recursiveUpdate acc (f name value))) { } attrs;

  # Iterate all attrs in base and return
  # the merged set from all iterated keys in base from
  # return path
  # lib.mySystem.mkMergeMap = base: return: builtins.concatMap (cfg: (cfg.return)) (builtins.attrValues base);

}

# # useful?
# foldlAttrs
# # attrbypath?
# let
