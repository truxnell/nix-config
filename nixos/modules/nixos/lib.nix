{ lib, config, pkgs, ... }:
with lib;
{

  # container builder
  lib.mySystem.mkContainer = options: (
    let
      # nix doesnt have an exhausive list of options for oci
      # so here i try to get a robust list of security options for containers
      # because everyone needs more tinfoild hat right?  RIGHT?

      containerExtraOptions = lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "privileged" ] false options) [ "--privileged" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "readOnly" ] false options) [ "--read-only" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "tmpfs" ] false options) [ (map (folders: "--tmpfs=${folders}") tmpfsFolders) ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "noNewPrivileges" ] false options) [ "--security-opt=no-new-privileges" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "dropAll" ] false options) [ "--cap-drop=ALL" ]

      ;

    in
    {
      ${options.app} = mkIf options.container.enable {
        image = "${options.container.image}";
        user = "${options.user}:${options.group}";
        environment = {
          TZ = config.time.timeZone;
        } // options.env;
        environmentFiles = lib.attrsets.attrByPath [ "container" "envFiles" ] [ ] options;
        volumes = [ "/etc/localtime:/etc/localtime:ro" ]
          ++ lib.optionals (lib.attrsets.hasAttrByPath [ "container" "persistentFolderMount" ] options) [
          "${options.persistence.folder}:${options.container.persistentFolderMount}:rw"
        ]
          ++ lib.attrsets.attrByPath [ "container" "volumes" ] [ ] options;

        extraOptions = containerExtraOptions;
      };
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
        # remove stale locks - this avoids some occasional annoyance
        #
        ${pkgs.restic}/bin/restic unlock --remove-all || true
      '';

    in
    {
      # local backup
      "${options.app}-local" = {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        passwordFile = config.sops.secrets."services/restic/password".path;
        exclude = excludePath;
        repository = "${config.mySystem.system.resticBackup.local.location}/${options.appFolder}";
        # inherit (options) user;
      };

      # remote backup
      "${options.app}-remote" = {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        environmentFile = config.sops.secrets."services/restic/env".path;
        passwordFile = config.sops.secrets."services/restic/password".path;
        repository = "${config.mySystem.system.resticBackup.remote.location}/${options.appFolder}";
        exclude = excludePath;
        # inherit (options) user;
      };

    }
  );

}
