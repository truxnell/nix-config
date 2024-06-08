{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.openvscode-server;
  app = "openvscode-server";
  url = "code-${config.networking.hostName}.${config.networking.domain}";
in
{
  options.mySystem.services.openvscode-server =
    {
      enable = mkEnableOption "openvscode-server";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {

    services.openvscode-server = {
      enable = true;
      telemetryLevel = "off";
      package = pkgs.unstable.openvscode-server; # TODO move to stable in 24.05?
      # serverDataDir
      user = "truxnell";
      host = "0.0.0.0";
      extraPackages = with pkgs;[ nixpkgs-fmt nixd fish tmux ];
      serverDataDir = "/var/lib/openvscode-server/server";
      extensionsDir = "/var/lib/openvscode-server/extensions";
      userDataDir = "/var/lib/openvscode-server/user";
      withoutConnectionToken = true;
    };

    services.nginx.virtualHosts."code-${config.networking.hostName}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.openvscode-server.port}";
        proxyWebsockets = true;
      };
    };

    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        "code-${config.networking.hostName}" = {
          icon = "vscode.svg";
          href = "https://${url}";

          description = "Code editor";
          container = "${app}";
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = "${app}-${config.networking.hostName}";
      group = "services";
      url = "https://${url}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];


  };
}
