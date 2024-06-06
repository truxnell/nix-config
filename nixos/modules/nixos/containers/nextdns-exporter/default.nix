{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "nextdns-exporter";
  category = "services";
  description = "NextDNS exporter";
  image = "ghcr.io/raylas/nextdns-exporter:0.5.4@sha256:9e41d74d3bda8cf0f65b2fddf5300332a22bd540cbe8226b9cc88583dc35f6ff";
  user = "568"; #string
  group = "568"; #string
  port = 9948; #int
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
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "${app}.service" ];
    };

    virtualisation.oci-containers.containers = config.lib.mySystem.mkContainer {
      inherit app image user group;
      env = { };
      ports = [ "${builtins.toString port}:${builtins.toString port}" ];
      envFiles = [ config.sops.secrets."${category}/${app}/env".path ];
    };


    services.vmagent = {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "nextdns";
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



    # homepage integration
    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${url}";
          inherit description;
        };
      }
    ];


    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };



  };
}
