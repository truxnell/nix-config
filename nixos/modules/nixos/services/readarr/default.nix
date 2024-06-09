{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "readarr";
  category = "services";
  description = "Book managment";
  # image = "";
  user = "kah"; #string
  group = "kah"; #string
  port = 8787; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;
        };
      prometheus = mkOption
        {
          type = lib.types.bool;
          description = "Enable prometheus scraping";
          default = true;
        };
      addToDNS = mkOption
        {
          type = lib.types.bool;
          description = "Add to DNS list";
          default = true;
        };
      dev = mkOption
        {
          type = lib.types.bool;
          description = "Development instance";
          default = false;
        };
      backup = mkOption
        {
          type = lib.types.bool;
          description = "Enable backups";
          default = true;
        };

    };

  config = mkIf cfg.enable
    {

      ## Secrets
      sops.secrets."${category}/${app}/env" = {
        sopsFile = ./secrets.sops.yaml;
        owner = user;
        group = "kah";
        restartUnits = [ "${app}.service" ];
      };

      users.users.truxnell.extraGroups = [ group ];

      environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
        directories = [{ directory = appFolder; user = "568"; group = "568"; mode = "750"; }];
      };


      ## service
      services.readarr = {
        enable = true;
        dataDir = appFolder;
        inherit group;
      };



      # homepage integration
      mySystem. services. homepage. infrastructure = mkIf cfg.addToHomepage [
        {
          ${ app} = {
            icon = "${ app}.svg";
            href = "https://${ url}";
            inherit description;
          };
        }
      ];

      ### gatus integration
      mySystem.services.gatus.monitors = mkIf cfg.monitor [
        {
          name = app;
          group = "${category}";
          url = "https://${url}";
          interval = "1m";
          conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
        }
      ];

      ### Ingress
      services.nginx.virtualHosts.${url} = {
        forceSSL = true;
        useACMEHost = config.networking.domain;
        locations."^~ /" = {
          proxyPass = "http://127.0.0.1:${builtins.toString port}";
        };
      };

      ### backups
      warnings = [
        (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
          "WARNING: Backups for ${app} are disabled!")
      ];

      services.restic.backups = mkIf cfg.backup (config.lib.mySystem.mkRestic
        {
          inherit app user;
          paths = [ appFolder ];
          inherit appFolder;
        });

    };
}
