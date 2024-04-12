{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.syncthing;
in
{
  options.mySystem.services.syncthing.enable = mkEnableOption "Syncthing";
  options.mySystem.services.syncthing.openFirewall = mkEnableOption "Syncthing" // { default = true; };

  config = mkIf cfg.enable {

    services.syncthing = {
      enable = true;
      group = "users";
      guiAddress = "0.0.0.0:8384";
      urAccepted = -1; # decline telemetry
      openDefaultPorts = cfg.openFirewall;

    };
    mySystem.services.traefik = [{
      http.routers.syncthing = {
        rule = "Host(`syncthing.${config.mySystem.domain}`)";
        entrypoints = "websecure";
        middlewares = "local-ip-only@file";
        service = "syncthing";
      };
      http.routers.syncthing.loadbalancer.server = {
        port = "8384";
      };
    }];
  };
}
