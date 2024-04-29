{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.openvscode-server;
  app = "openvscode-server";
in
{
  options.mySystem.services.openvscode-server.enable = mkEnableOption "openvscode-server";

  config = mkIf cfg.enable {

    services.openvscode-server = {
      enable = true;
      telemetryLevel = "off";
      package = pkgs.unstable.openvscode-server; # TODO move to stable in 24.05?
      # serverDataDir
      user = "truxnell";
      host = "0.0.0.0";
      extraPackages = with pkgs;[ fish tmux ];
      withoutConnectionToken = true;
    };

    mySystem.services.traefik.routers = [{
      http.routers.${app} = {
        rule = "Host(`code-d.${config.mySystem.domain}`)";
        entrypoints = "websecure";
        middlewares = "local-ip-only@file";
        service = "${app}";
      };
      http.services.${app} = {
        loadBalancer = {
          servers = [{
            url = "http://localhost:${builtins.toString config.services.openvscode-server.port}";
          }];
        };
      };

    }];

  };
}
