{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "gatus";
  image = "ghcr.io/twin/gatus:v5.8.0@sha256:fecb4c38722df59f5e00ab4fcf2393d9b8dad9161db208d8d79386dc86da8a55";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
  cfg = config.mySystem.services.${app};
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";
  containerPersistentFolder = "/config";
  extraEndpoints = [
    {
      name = "firewall";
      group = "servers";
      url = "icmp://unifi.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "pikvm";
      group = "servers";
      url = "icmp://pikvm.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "octoprint";
      group = "servers";
      url = "icmp://prusa.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "icarus";
      group = "k8s";
      url = "icmp://icarus.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "xerxes";
      group = "k8s";
      url = "icmp://xerxes.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "shodan";
      group = "k8s";
      url = "icmp://shodan.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }

    {
      name = "daedalus";
      group = "servers";
      url = "icmp://daedalus.l.trux.dev";
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "dns01 external dns";
      group = "dns";
      url = "dns01.l.trux.dev";
      dns = {
        query-name = "cloudflare.com";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }
    {
      name = "dns02 external dns";
      group = "dns";
      url = "dns02.l.trux.dev";
      dns = {
        query-name = "cloudflare.com";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }
    {
      name = "dns01 internal dns";
      group = "dns";
      url = "dns01.l.trux.dev";
      dns = {
        query-name = "unifi.l.trux.dev";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }
    {
      name = "dns02 internal dns";
      group = "dns";
      url = "dns02.l.trux.dev";
      dns = {
        query-name = "unifi.l.trux.dev";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }
    {
      name = "dns01 split DNS";
      group = "dns";
      url = "dns01.l.trux.dev";
      dns = {
        query-name = "${app}.trux.dev";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }
    {
      name = "dns02 split DNS";
      group = "dns";
      url = "dns02.l.trux.dev";
      dns = {
        query-name = "${app}.trux.dev";
        query-type = "A";
      };
      interval = "30s";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    }


  ] ++ config.mySystem.services.gatus.monitors;

  configAlerting = {
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
  configVar =
    {
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
  options.mySystem.services.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
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
      user = "${user}:${group}";
      environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${configFile}:/config/config.yaml:ro"
      ];

      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };

      extraOptions = [ "--cap-add=NET_RAW" ]; # Required for ping/etc to do monitoring
    };

    mySystem.services.homepage.infrastructure-services = mkIf cfg.addToHomepage [
      {
        "Gatus Internal" = {
          icon = "${app}.png";
          href = "https://${app}.${config.networking.domain}";
          description = "Internal Infrastructure Monitoring";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.networking.domain}";
          };
        };
      }
    ];
  };
}
