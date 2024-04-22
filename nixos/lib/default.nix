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
      envFiles = existsOrDefault "envFiles" options [ ];
      addTraefikLabels = existsOrDefault "container.addTraefikLabels" options false;
      homepageIcon = existsOrDefault "homepage.icon" options "${options.app}.svg";
      appUrl = existsOrDefault "appUrl" options "https://${options.app}.${options.domain}";
    in
    {
      virtualisation.oci-containers.containers.${options.app} = {
        image = "${options.image}";
        user = "${user}:${group}";
        environment = {
          TZ = options.timeZone;
        } // options.container.env;
        environmentFiles = [ ] ++ envFiles;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
        ];

        labels = mkIf addTraefikLabels (mkTraefikLabels {
          name = options.app;
          port = options.port;
          domain = options.domain;
          url = appUrl;
        });

        # extraOptions = [ "--cap-add=NET_RAW" ]; # Required for ping/etc to do monitoring
      };

      mySystem.services.homepage.media-services = mkIf options.addToHomepage [
        {
          ${options.app} = {
            icon = homepageIcon;
            href = appUrl;
            url = appUrl;
            description = options.description;
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
      url = existsOrDefault "url" options "https://${options.name}.${options.domain}";

      # created if port is specified
      service = if builtins.hasAttr "service" options then options.service else options.name;
      middleware = if builtins.hasAttr "middleware" options then options.middleware else "local-ip-only@file";
    in
    {
      "traefik.enable" = "true";
      "traefik.http.routers.${name}.rule" = "Host(`${url}`)";
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
