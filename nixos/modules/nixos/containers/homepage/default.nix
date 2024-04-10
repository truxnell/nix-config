{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "homepage";
  image = "ghcr.io/gethomepage/homepage:v0.8.11";
  user = "568"; #string
  group = "568"; #string
  port = 3000; #int
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";

  cfg = config.mySystem.services.homepage;

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
        href = "https://10.8.10.1";
        description = "Unifi Dream Machine Pro";
        icon = "ubiquiti";
        widget = {
          url = "https://10.8.10.1:443";
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
        href = "http://prusa:5000"; # TODO fix with better hostname
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
    { Infrastructure = cfg.infrastructure-services ++ extraInfrastructure; }
    { Home = cfg.home-services ++ extraHome; }
    { Media = cfg.media-services; }
  ];
  servicesFile = builtins.toFile "homepage-config.yaml" (builtins.toJSON services);
  emptyFile = builtins.toFile "docker.yaml" (builtins.toJSON [{ }]);

in
{
  options.mySystem.services.homepage = {
    enable = mkEnableOption "Homepage dashboard";
    infrastructure-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
    home-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
    media-services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Services to add to the infrastructure column";
      default = [ ];
    };
  };

  config = mkIf cfg.enable {

    # homepage secrets
    # ensure you dont have whitespace around your ='s!
    # ex: HOMEPAGE_VAR_CLOUDFLARE_TUNNEL_API="supersecretlol"
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
      sopsFile = ../arr/sonarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/radarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../arr/radarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/lidarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../arr/lidarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/readarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../arr/readarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };
    sops.secrets."services/prowlarr/env" = {
      # configure secret for forwarding rules
      sopsFile = ../arr/prowlarr/secrets.sops.yaml;
      owner = "kah";
      group = "kah";
      restartUnits = [ "podman-${app}.service" ];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";

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
      ];

      # labels = {
      #   "traefik.enable" = "true";
      #   "traefik.http.routers.${app}.entrypoints" = "websecure";
      #   "traefik.http.routers.${app}.middlewares" = "local-ip-only@file";
      #   "traefik.http.services.${app}.loadbalancer.server.port" = "${toString port}";
      # };
      labels = config.lib.mySystem.mkTraefikLabels {
        name = app;
        inherit port;
      };
      # not using docker socket for discovery, just
      # building up the apps from a shared key
      # this is a bit more tedious, but more secure
      # from not exposing docker socet and makes it
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

    mySystem.services.gatus.monitors = mkIf config.mySystem.services.gatus.enable [{
      name = app;
      group = "infrastructure";
      url = "https://${app}.${config.networking.domain}";
      interval = "30s";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];


  };
}
