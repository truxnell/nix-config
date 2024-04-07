{ lib
, config
, pkgs
, ...
}:
with lib;
let
  app = "homepage";
  image = "ghcr.io/gethomepage/homepage:v0.8.10";
  user = "568"; #string
  group = "568"; #string
  port = 3000; #int
  persistentFolder = "${config.mySystem.persistentFolder}/${app}";

  cfg = config.mySystem.services.homepage;

  settings = {
    # title = "Hades";
    # theme = "dark";
    # color = "slate";
    showStats = true;
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
      search = {
        provider = "duckduckgo";
        target = "_blank";
      };
    }
  ];
  widgetsFile = builtins.toFile "homepage-widgets.yaml" (builtins.toJSON widgets);

  services = [
    { Infrastructure = cfg.infrastructure-services; }
    { Home = cfg.home-services; }
    { Media = cfg.media-services; }
  ];
  servicesFile = builtins.toFile "homepage-config.yaml" (builtins.toJSON services);
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

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "${user}:${group}";

      environment = {
        UMASK = "002";
        PUID = "${user}";
        PGID = "${group}";
      };

      environmentFiles = [
        config.sops.secrets."services/sonarr/env".path
        config.sops.secrets."services/radarr/env".path
        config.sops.secrets."services/readarr/env".path
        config.sops.secrets."services/lidarr/env".path
        config.sops.secrets."services/prowlarr/env".path
      ];

      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.middlewares" = "local-only@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "${toString port}";
      };
      # not using docker socket for discovery, just
      # building up the apps from a shared key
      # this is a bit more tedious, but more secure
      # from not exposing docker socet and makes it 
      # easier to have/move services between hosts
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${persistentFolder}:/app/config/logs:rw"
        "${settingsFile}:/app/config/settings.yaml"
        "${servicesFile}:/app/config/services.yaml"
        "${bookmarksFile}:/app/config/bookmarks.yaml"
        "${widgetsFile}:/app/config/widgets.yaml"

      ];

    };

  };
}
