{ lib, config, ... }:
{


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

}
