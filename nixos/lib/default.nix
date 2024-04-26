{ inputs, lib, ... }:

with lib;
rec {

  firstOrDefault = first: default: if !isNull first then first else default;

  existsOrDefault = x: set: default: if builtins.hasAttr x set then builtins.getAttr x set else default;

  # Will be v. useful when i grok
  # https://github.com/ahbk/my-nixos/blob/5fe1521b11422c66fd823b442393b3b044a5a5b8/nix#L5
  # pick a list of attributes from an attrSet
  # mySystem.pick = attrNames: attrSet: filterAttrs (name: value: elem name attrNames) attrSet;

  # create an env-file (package) that can be sourced to set environment variables
  # mySystem.mkEnv = name: value: pkgs.writeText "${name}-env" (concatStringsSep "\n" (mapAttrsToList (n: v: "${n}=${v}") value));

  # loop over an attrSet and merge the attrSets returned from f into one (latter override the former in case of conflict)
  # mySystem.mergeAttrs = f: attrs: builtins.foldlAttrs (acc: name: value: (recursiveUpdate acc (f name value))) { } attrs;

  # main service builder
  mkService = options: (
    let
      user = existsOrDefault "user" options "568";
      group = existsOrDefault "group" options "568";

      addTraefikLabels = if (builtins.hasAttr "container" options) && (builtins.hasAttr "addTraefikLabels" options.container) then options.container.addTraefikLabels else true;
      addToHomepage = lib.attrsets.attrByPath [ "homepage" "enable" ] true options;
      homepageIcon = if (builtins.hasAttr "homepage" options) && (builtins.hasAttr "icon" options.homepage) then options.homepage.icon else "${options.app}.svg";
      subdomain = existsOrDefault "subdomainOverride" options options.app;
      host = existsOrDefault "host" options "${subdomain}.${options.domain}";

      # nix doesnt have an exhausive list of options for oci
      # so here i try to get a robust list of security options for containers
      # because everyone needs more tinfoild hat right?  RIGHT?

      containerExtraOptions = [ ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "privileged" ] false options) [ "--privileged" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "readOnly" ] false options) [ "--read-only" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "tmpfs" ] false options) [ (map (folders: "--tmpfs=${folders}") tmpfsFolders) ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "noNewPrivileges" ] false options) [ "--security-opt=no-new-privileges" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "dropAll" ] false options) [ "--cap-drop=ALL" ]

      ;

    in
    {
      virtualisation.oci-containers.containers.${options.app} = mkIf options.container.enable {
        image = "${options.container.image}";
        user = "${user}:${group}";
        environment = {
          TZ = options.timeZone;
        } // options.container.env;
        environmentFiles = [ ]
          ++ lib.attrsets.attrByPath [ "container" "envFiles" ] [ ] options;
        volumes = [ "/etc/localtime:/etc/localtime:ro" ]
          ++ lib.optionals (lib.attrsets.hasAttrByPath [ "container" "persistentFolderMount" ] options) [
          "${options.persistence.folder}:${options.container.persistentFolderMount}:rw"
        ]
          ++ lib.attrsets.attrByPath [ "container" "volumes" ] [ ] options;


        labels = mkIf addTraefikLabels (mkTraefikLabels {
          name = subdomain;
          port = options.port;
          domain = options.domain;
          url = host;
        });

        extraOptions = containerExtraOptions;
      };

      systemd.tmpfiles.rules = [ ]
        ++ lib.optionals (lib.attrsets.hasAttrByPath [ "persistence" "folder" ] options) [ "d ${options.persistence.folder} 0755 ${user} ${group} -" ]
      ;

      # built a entry for homepage
      mySystem.services.homepage.${options.homepage.category} = mkIf addToHomepage [
        {
          ${options.app} = {
            icon = homepageIcon;
            href = "https://${ host }";
            host = host;
            description = options.description;
          };
        }
      ];

      #build backups if required - default super duper true
      services.restic.backups = config.lib.mySystem.mkRestic
        {
          inherit app;
          user = builtins.toString user;
          excludePaths = [ ]
            ++ lib.optionals (lib.attrsets.hasAttrByPath [ "persistence" "excludeFolders" ] options) [ options.persistence.excludeFolders ];
          paths = [ appFolder ];
          inherit appFolder;
        };

    }


  );

  # build up traefik docker labels
  mkTraefikLabels = options: (
    let
      inherit (options) name;
      subdomain = if builtins.hasAttr "subdomain" options then options.subdomain else options.name;
      host = existsOrDefault "host" options "${options.name}.${options.domain}";

      # created if port is specified
      service = if builtins.hasAttr "service" options then options.service else options.name;
      middleware = if builtins.hasAttr "middleware" options then options.middleware else "local-ip-only@file";
    in
    {
      "traefik.enable" = "true";
      "traefik.http.routers.${name}.rule" = "Host(`${host}`)";
      "traefik.http.routers.${name}.entrypoints" = "websecure";
      "traefik.http.routers.${name}.middlewares" = "${middleware}";
    } // attrsets.optionalAttrs (builtins.hasAttr "port" options) {
      "traefik.http.routers.${name}.service" = service;
      "traefik.http.services.${service}.loadbalancer.server.port" = "${builtins.toString options.port}";
    } // attrsets.optionalAttrs (builtins.hasAttr "scheme" options) {
      "traefik.http.routers.${name}.service" = service;
      "traefik.http.services.${service}.loadbalancer.server.scheme" = "${options.scheme}";
    } // attrsets.optionalAttrs (builtins.hasAttr "service" options) {
      "traefik.http.routers.${name}.service" = service;
    }
  );

  # build a restic restore set for both local and remote
  mkRestic = options: (
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
      "${options.app}-local" = mkIf config.mySystem.system.resticBackup.local.enable {
        inherit pruneOpts timerConfig initialize backupPrepareCommand;
        # Move the path to the zfs snapshot path
        paths = map (x: "${config.mySystem.persistentFolder}/.zfs/snapshot/restic_nightly_snap/${x}") options.paths;
        passwordFile = config.sops.secrets."services/restic/password".path;
        exclude = excludePath;
        repository = "${config.mySystem.system.resticBackup.local.location}/${options.appFolder}";
        # inherit (options) user;
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
        # inherit (options) user;
      };

    }
  );

}
