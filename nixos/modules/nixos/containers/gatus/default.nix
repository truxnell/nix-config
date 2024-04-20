{ lib
, config
, pkgs
, self
, ...
}:
with lib;
let
  app = "gatus";
  image = "ghcr.io/twin/gatus:v5.9.0@sha256:7eb33f6efa63047f77aa93893c821af831fd54c03ebb4dd3bc123997e55258bf";
  user = "568"; #string
  group = "568"; #string
  port = 8080; #int
  cfg = config.mySystem.services.${app};
  appFolder = "containers/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
  containerPersistentFolder = "/config";
  extraEndpoints = [
    # TODO refactor these out into their own file or fake host?
    {
      name = "firewall";
      group = "servers";
      url = "icmp://unifi.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "pikvm";
      group = "servers";
      url = "icmp://pikvm.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "octoprint";
      group = "servers";
      url = "icmp://prusa.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "icarus";
      group = "k8s";
      url = "icmp://icarus.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "xerxes";
      group = "k8s";
      url = "icmp://xerxes.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "shodan";
      group = "k8s";
      url = "icmp://shodan.${config.mySystem.internalDomain}";
      interval = "1m";
      alerts = [{ type = "pushover"; }];
      conditions = [ "[CONNECTED] == true" ];
    }



  ] ++ builtins.concatMap (cfg: cfg.config.mySystem.services.gatus.monitors)
    (builtins.attrValues self.nixosConfigurations);

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
          icon = "${app}.svg";
          href = "https://${app}.${config.mySystem.domain}";
          description = "Internal Infrastructure Monitoring";
          container = "${app}";
          widget = {
            type = "${app}";
            url = "https://${app}.${config.mySystem.domain}";
          };
        };
      }
    ];
  };
}
