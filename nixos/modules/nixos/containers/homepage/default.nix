{ lib
, config
, pkgs
, self
, ...
}:
with lib;
let
  app = "homepage";
  image = "ghcr.io/gethomepage/homepage:v0.10.6";
  user = "kah"; #string
  group = "kah"; #string
  port = 3000; #int
  cfg = config.mySystem.services.${app};
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";

  # TODO refactor out this sht
  settings =
    {
      title = "NatFlix";
      theme = "dark";
      color = "slate";
      showStats = true;
      disableCollape = true;
      cardBlur = "md";
      statusStyle = "none";

      datetime = {
        text_size = "l";
        format = {
          timeStyle = "short";
          dateStyle = "short";
          hourCycle = "h23";
        };
      };

      providers = {
        openweathermap = "{{HOMEPAGE_VAR_OPENWEATHERMAP_API_KEY}}";
      };
    };

  settingsFile = builtins.toFile "homepage-settings.yaml" (builtins.toJSON settings);

  bookmarks = [
    {
      Administration = [
        { Source = [{ icon = "github.png"; href = "https://github.com/truxnell/nix-config"; }]; }
        { Cloudflare = [{ icon = "cloudflare.png"; href = "https://dash.cloudflare.com/"; }]; }
      ];
    }
    {
      Development = [
        { CyberChef = [{ icon = "cyberchef.png"; href = "https://gchq.github.io/CyberChef/"; }]; }
        { "Nix Options Search" = [{ abbr = "NS"; href = "https://search.nixos.org/packages"; }]; }
        { "Doppler Secrets" = [{ abbr = "DP"; href = "https://dashboard.doppler.com"; }]; }
        { "onedr0p Containers" = [{ abbr = "OC"; href = "https://github.com/onedr0p/containers"; }]; }
        { "bjw-s Containers" = [{ abbr = "BC"; href = "https://github.com/bjw-s/container-images"; }]; }

      ];
    }
  ];
  bookmarksFile = builtins.toFile "homepage-bookmarks.yaml" (builtins.toJSON bookmarks);

  widgets = [
    {
      resources = {
        cpu = true;
        memory = true;
        cputemp = true;
        uptime = true;
        disk = "/";
        units = "metric";
        # label = "system";
      };
    }
    {
      datetime = {
        text_size = "l";
        locale = "au";
        format = {
          timeStyle = "short";
          dateStyle = "short";
          hourCycle = "h23";
        };
      };
    }
    {
      openmeteo = {
        label = "Melbourne";
        latitude = "-37.8136";
        longitude = "144.9631";
        timezone = config.time.timeZone;
        units = "metric";
        cache = 5;
      };
    }
  ];
  widgetsFile = builtins.toFile "homepage-widgets.yaml" (builtins.toJSON widgets);

  extraInfrastructure = [
    {
      "UDMP" = {
        href = "https://unifi.${config.mySystem.internalDomain}";

        description = "Unifi Dream Machine Pro";
        icon = "ubiquiti";
        widget = {
          url = "https://unifi.${config.mySystem.internalDomain}";
          username = "unifi_read_only";
          password = "{{HOMEPAGE_VAR_UNIFI_PASSWORD}}";
          type = "unifi";
        };
      };
    }
    {
      "Nextdns" = {
        href = "https://my.nextdns.io/";
        description = "Adblocking DNS";
        icon = "nextdns";
        widget = {
          profile = "{{HOMEPAGE_VAR_NEXTDNS_TRUSTED_PROFILE}}";
          key = "{{HOMEPAGE_VAR_NEXTDNS_API_KEY}}";
          type = "nextdns";
        };
      };
    }
    {
      "Cloudflare" = {
        href = "https://dash.cloudflare.com";
        description = "DNS and security provider";
        icon = "cloudflare";
        widget = {
          key = "{{HOMEPAGE_VAR_CLOUDFLARE_TUNNEL_API}}";
          accountid = "{{HOMEPAGE_VAR_CLOUDFLARE_ACCOUNT_ID}}";
          tunnelid = "{{HOMEPAGE_VAR_CLOUDFLARE_TUNNEL_ID}}";
          type = "cloudflared";
        };
      };
    }

  ];

  extraHome = [
    {
      "Prusa Octoprint" = {
        href = "http://prusa.${config.mySystem.internalDomain}:5000";

        description = "Prusa MK3s 3D printer";
        icon = "octoprint";
        widget = {
          type = "octoprint";
          url = "http://prusa:5000";
          key = "{{HOMEPAGE_VAR_PRUSA_OCTOPRINT_API}}";
        };
      };
    }
  ];

  services = [
    {
      Infrastructure = builtins.concatMap (cfg: cfg.config.mySystem.services.homepage.infrastructure)
        (builtins.attrValues self.nixosConfigurations) ++ extraInfrastructure;
    }
    {
      Home = builtins.concatMap (cfg: cfg.config.mySystem.services.homepage.home)
        (builtins.attrValues self.nixosConfigurations) ++ extraHome;
    }
    {
      Media = builtins.concatMap (cfg: cfg.config.mySystem.services.homepage.media)
        (builtins.attrValues self.nixosConfigurations);
    }
  ];
  servicesFile = builtins.toFile "homepage-config.yaml" (builtins.toJSON services);
  emptyFile = builtins.toFile "docker.yaml" (builtins.toJSON [{ }]);

in
{
  options.mySystem.services.homepage = {
    enable = mkEnableOption "Homepage dashboard";
    infrastructure = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
    home = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
    media = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
  };

  config = mkIf cfg.enable {

    # homepage secrets
    # ensure you dont have whitespace around your ='s!
    # ex: HOMEPAGE_VAR_CLOUDFLARE_TUNNEL_API=supersecretlol
    sops.secrets."services/homepage/env" = {
      # configure secret for forwarding rules
      sopsFile = ./secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };

    # api secrets from other apps
    sops.secrets."services/sonarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../../services/sonarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/radarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../../services/radarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/lidarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../../services/lidarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/readarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../../services/readarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/prowlarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../../services/prowlarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/adguardhome/env" = {
      sopsFile = ../../services/adguardhome/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };


    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "568:568";

      environment = {
        UMASK = "002";
        PUID = "${user}";
        PGID = "${group}";
        LOG_TARGETS = "stdout";
      };

      # secrets
      environmentFiles = [
        config.sops.secrets."services/homepage/env".path

        config.sops.secrets."services/sonarr/env".path
        config.sops.secrets."services/radarr/env".path
        config.sops.secrets."services/readarr/env".path
        config.sops.secrets."services/lidarr/env".path
        config.sops.secrets."services/prowlarr/env".path
        config.sops.secrets."services/adguardhome/env".path

      ];

      # not using docker socket for discovery, just
      # building up the apps from a shared key
      # this is a bit more tedious, but more secure
      # from not exposing docker socket and makes it
      # easier to have/move services between hosts
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${settingsFile}:/app/config/settings.yaml:ro"
        "${servicesFile}:/app/config/services.yaml:ro"
        "${bookmarksFile}:/app/config/bookmarks.yaml:ro"
        "${widgetsFile}:/app/config/widgets.yaml:ro"
        "${emptyFile}:/app/config/docker.yaml:ro"
        "${emptyFile}:/app/config/kubernetes.yaml:ro"
      ];

      extraOptions = [
        "--read-only"
        "--tmpfs=/app/config"
      ];
    };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";

      };
    };


    mySystem.services.gatus.monitors = [{
      name = app;
      group = "infrastructure";
      url = "https://${app}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];


  };
}
