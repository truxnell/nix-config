{
  lib,
  config,
  self,
  ...
}:
with lib;
let
  app = "gatus";
  image = "ghcr.io/twin/gatus:v5.29.0@sha256:b4afbcaf1cdfcda0b87e732914f101b0e2fab71485ae5d691ceb7b97d021b642";
  user = "kah"; # string
  group = "kah"; # string
  port = 8080; # int
  cfg = config.mySystem.services.${app};

  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  extraEndpoints = [
    # TODO refactor these out into their own file or fake host?
    {
      name = "firewall";
      group = "servers";
      url = "icmp://unifi.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [ { type = "pushover"; } ];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "pikvm";
      group = "servers";
      url = "icmp://pikvm.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [ { type = "pushover"; } ];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "weather station";
      group = "servers";
      url = "icmp://ESP-B9C83C.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [ { type = "pushover"; } ];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "zigbee";
      group = "servers";
      url = "icmp://espressif.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [ { type = "pushover"; } ];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "brewpi fridge";
      group = "servers";
      url = "icmp://ESP-7DE997.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [ { type = "pushover"; } ];
      conditions = [ "[CONNECTED] == true" ];
    }

  ]
  ++ builtins.concatMap (cfg: cfg.config.mySystem.services.gatus.monitors) (
    builtins.attrValues self.nixosConfigurations
  );

  configAlerting = {
    # TODO really should make this libdefault and let modules overwrite failure-threshold etc.
    pushover = {
      title = "${app} Internal";
      application-token = "$PUSHOVER_APP_TOKEN";
      user-key = "$PUSHOVER_USER_KEY";
      default-alert = {
        failure-threshold = 5;
        success-threshold = 2;
        send-on-resolved = true;
      };
    };
  };
  configVar = {
    metrics = true;
    endpoints = extraEndpoints;
    alerting = configAlerting;
    ui = {
      title = "Home Status | Gatus";
      header = "Home Status";
    };
  };

  configFile = builtins.toFile "config.yaml" (builtins.toJSON configVar);

in
{
  options.mySystem.services.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add for montoring";
      default = [ ];
    };

  };

  config = mkIf cfg.enable {
    sops.secrets."services/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
      restartUnits = [ "podman-${app}.service" ];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${configFile}:/config/config.yaml:ro"

      ];

      extraOptions = [ "--cap-add=NET_RAW" ]; # Required for ping/etc to do monitoring
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    services.vmagent = {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "gatus";
            # scrape_timeout = "40s";
            static_configs = [
              {
                targets = [ "https://${app}.${config.mySystem.domain}" ];
              }
            ];
          }
        ];
      };
    };

  };
}
