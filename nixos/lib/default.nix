{ inputs, lib, ... }:

with lib;
rec {

  firstOrDefault = first: default: if first != null then first else default;

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

      enableBackups = (lib.attrsets.hasAttrByPath [ "persistence" "folder" ] options)
        && (lib.attrsets.attrByPath [ "persistence" "enable" ] true options);
      # nix doesnt have an exhausive list of options for oci
      # so here i try to get a robust list of security options for containers
      # because everyone needs more tinfoild hat right?  RIGHT?

      containerExtraOptions = lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "privileged" ] false options) [ "--privileged" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "readOnly" ] false options) [ "--read-only" ]
        ++ lib.optionals (lib.attrsets.attrByPath [ "container" "caps" "tmpfs" ] false options) [ (map (folders: "--tmpfs=${folders}") container.caps.tmpfsFolders) ]
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
        environmentFiles = lib.attrsets.attrByPath [ "container" "envFiles" ] [ ] options;
        volumes = [ "/etc/localtime:/etc/localtime:ro" ]
          ++ lib.optionals (lib.attrsets.hasAttrByPath [ "container" "persistentFolderMount" ] options) [
          "${options.persistence.folder}:${options.container.persistentFolderMount}:rw"
        ]
          ++ lib.attrsets.attrByPath [ "container" "volumes" ] [ ] options;


        labels = mkIf addTraefikLabels (mkTraefikLabels {
          name = subdomain;
          inherit (options) port;
          inherit (options) domain;
          url = host;
        });

        extraOptions = containerExtraOptions;
      };

      systemd.tmpfiles.rules = lib.optionals (lib.attrsets.hasAttrByPath [ "persistence" "folder" ] options) [ "d ${options.persistence.folder} 0750 ${user} ${group} -" ]
      ;

      # built a entry for homepage
      mySystem.services.homepage.${options.homepage.category} = mkIf addToHomepage [
        {
          ${options.app} = {
            icon = homepageIcon;
            href = "https://${ host }";
            inherit host;
            inherit (options) description;
          };
        }
      ];

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

}
