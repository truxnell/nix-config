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
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "pikvm";
      group = "servers";
      url = "icmp://pikvm.l.trux.dev";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "octoprint";
      group = "servers";
      url = "icmp://prusa.l.trux.dev";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "icarus";
      group = "k8s";
      url = "icmp://icarus.l.trux.dev";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "xerxes";
      group = "k8s";
      url = "icmp://xerxes.l.trux.dev";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }
    {
      name = "helios";
      group = "k8s";
      url = "icmp://helios.l.trux.dev";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" ];
    }
  ] ++ config.mySystem.services.gatus.monitors;
  configVar =
    {
      metrics = true;
      endpoints = extraEndpoints;
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
    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period

    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";
      # environmentFiles = [ config.sops.secrets."services/${app}/env".path ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${persistentFolder}:/config:rw"
        "${configFile}:/config/config.yaml:ro"
      ];

      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        port = port;
      };

      extraOptions = [ "--cap-add=NET_RAW" ];
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
            url = "http://${app}:${toString port}";
          };
        };
      }
    ];
  };
}
