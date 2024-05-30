{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "unpoller";
  category = "services";
  description = "";
  image = "";
  user = "unpoller-exporter"; #string
  group = "unpoller-exporter"; #string
  port = 9130; #int
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

  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."${category}/${app}/pass" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];


    # Folder perms - only for containers
    # systemd.tmpfiles.rules = [
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };


    ## service
    services.prometheus.exporters.unpoller = {
      enable = true;
      controllers = [{
        url = "https://10.8.10.1";
        verify_ssl = false;
        user = "unifi_read_only";
        pass = config.sops.secrets."${category}/${app}/pass".path;
        save_ids = true;
        save_events = true;
        save_alarms = true;
        save_anomalies = true;
        # save_dpi = true;
        # save_sites=true;


      }];
    };

    services.vmagent = {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "unpoller";
            # scrape_timeout = "40s";
            static_configs = [
              {
                targets = [ "http://127.0.0.1:${builtins.toString port}" ];
              }
            ];
          }
        ];
      };
    };


  };
}
