{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.code-server;
  app = "code-server";
  url = "code-${config.networking.hostName}.${config.networking.domain}";
  appFolder = "/var/lib/${app}";
  user = "truxnell";
  group = "users";
in
{
  options.mySystem.services.code-server =
    {
      enable = mkEnableOption "code-server";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    };

  config = mkIf cfg.enable {

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };



    services.code-server = {
      auth = "none";
      enable = true;
      disableTelemetry = true;
      disableUpdateCheck = true;
      proxyDomain = "code-${config.networking.hostName}.${config.networking.domain}";
      userDataDir = "${appFolder}";
      host = "127.0.0.1";
      extraPackages = with pkgs; [
        git
        nix
        nixfmt-rfc-style
      ];
      package = pkgs.vscode-with-extensions.override {
        vscode = pkgs.code-server;
        vscodeExtensions = with pkgs.vscode-extensions;
          [
            # Nix
            jnoortheen.nix-ide
            mkhl.direnv
            streetsidesoftware.code-spell-checker
            oderwat.indent-rainbow


          ];
      };
      user = "truxnell";
    };
    services.nginx.virtualHosts."code-${config.networking.hostName}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.code-server.port}";
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
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 1500" ];
    }];


  };
}
