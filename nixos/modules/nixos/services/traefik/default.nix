{ lib
, config
, pkgs
, ...
}:
# ref: https://github.com/rishid/nix-config/blob/be0d5cbbe4df79ed2b2ba4714456f21777c72b38/modules/traefik/default.nix#L170
with lib;
let
  cfg = config.mySystem.services.traefik;
  routersFile = builtins.toFile "routers.yaml" (builtins.toJSON cfg.routers);

in
{
  options.mySystem.services.traefik = {
    enable = mkEnableOption "Traefik reverse proxy";
    routers = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      description = "Routers to add to traefik";
      default = [ ];
    };
  };


  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    sops.secrets."system/services/traefik/apiTokenFile".sopsFile = ./secrets.sops.yaml;

    # Restart when secret changes
    sops.secrets."system/services/traefik/apiTokenFile".restartUnits = [ "traefik.service" ];

    systemd.services.traefik = {
      serviceConfig.EnvironmentFile = [
        config.sops.secrets."system/services/traefik/apiTokenFile".path
      ];
    };

    # add user to group to view files/storage
    users.users.truxnell.extraGroups = [ config.services.traefik.group ];

    services.traefik = {
      # TODO refactor into subfiles
      enable = true;
      group = "podman"; # podman backend, required to access socket

      dataDir = "${config.mySystem.persistentFolder}/traefik";
      # Required so traefik is permitted to watch docker events
      # group = "docker";

      staticConfigOptions = {

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        api.dashboard = true;
        log.level = "DEBUG";

        # Allow backend services to have self-signed certs
        serversTransport.insecureSkipVerify = true;

        providers = {
          docker = {
            endpoint = "unix:///var/run/podman/podman.sock";
            exposedByDefault = false;
            defaultRule = "Host(`{{ normalize .Name }}.${config.mySystem.domain}`)";
            # network = "proxy";
          };
          file = {
            filename = routersFile;
            watch = true;
          };

        };

        # Listen on port 80 and redirect to port 443
        entryPoints.web = {
          address = ":80";
          http.redirections.entrypoint.to = "websecure";
        };

        # Run everything SSL
        entryPoints.websecure = {
          address = ":443";
          http = {
            tls = {
              certresolver = "letsencrypt";
              domains.main = "${config.mySystem.domain}";
              domains.sans = "*.${config.mySystem.domain}";
            };
          };
          http3 = { };
        };

        certificatesResolvers.letsencrypt.acme = {
          dnsChallenge.provider = "cloudflare";
          dnsChallenge.resolvers = [ "1.1.1.1:53" ];
          keyType = "EC256";
          storage = "${config.services.traefik.dataDir}/acme.json";
        };
        # };
      };
      # Dynamic configuration
      dynamicConfigOptions = {

        http.middlewares = {
          # Whitelist local network and VPN addresses
          local-ip-only.ipWhiteList.sourceRange = [
            "127.0.0.1/32" # localhost
            "192.168.0.0/16" # RFC1918
            "10.0.0.0/8" # RFC1918
            "172.16.0.0/12" # RFC1918 (docker network)
          ];

          # authelia = {
          #   # Forward requests w/ middlewares=authelia@file to authelia.
          #   forwardAuth = {
          #     # address = cfg.autheliaUrl;
          #     address = "http://localhost:9092/api/verify?rd=https://auth.dhupar.xyz:444/";
          #     trustForwardHeader = true;
          #     authResponseHeaders = [
          #       "Remote-User"
          #       "Remote-Name"
          #       "Remote-Email"
          #       "Remote-Groups"
          #     ];
          #   };
          # };
          # authelia-basic = {
          #   # Forward requests w/ middlewares=authelia-basic@file to authelia.
          #   forwardAuth = {
          #     address = "http://localhost:9092/api/verify?auth=basic";
          #     trustForwardHeader = true;
          #     authResponseHeaders = [
          #       "Remote-User"
          #       "Remote-Name"
          #       "Remote-Email"
          #       "Remote-Groups"
          #     ];
          #   };
          # };
          # https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/#forwardauth-with-static-upstreams-configuration
          # auth-headers = {
          #   browserXssFilter = true;
          #   contentTypeNosniff = true;
          #   forceSTSHeader = true;
          #   frameDeny = true;
          #   sslHost = domain;
          #   sslRedirect = true;
          #   stsIncludeSubdomains = true;
          #   stsPreload = true;
          #   stsSeconds = 315360000;
          # };
        };

        tls.options.default = {
          minVersion = "VersionTLS13";
          sniStrict = true;
        };

        # Set up wildcard domain certificates for both *.hostname.domain and *.local.domain
        http.routers = {
          traefik = {
            entrypoints = "websecure";
            rule = "Host(`traefik-${config.networking.hostName}.${config.mySystem.domain}`)";
            tls.certresolver = "letsencrypt";
            tls.domains = [{
              main = "${config.mySystem.domain}";
              sans = "*.${config.mySystem.domain}";
            }];
            middlewares = "local-ip-only@file";
            service = "api@internal";
          };
        };
      };
    };

    mySystem.services.homepage.infrastructure-services = [
      {
        "Traefik  ${config.networking.hostName}" = {
          icon = "traefik.png";
          href = "https://traefik-${config.networking.hostName}.${config.mySystem.domain}/dashboard/";

          description = "Reverse Proxy";
          widget = {
            type = "traefik";
            url = "https://traefik-${config.networking.hostName}.${config.mySystem.domain}";
          };
        };
      }
    ];

    mySystem.services.gatus.monitors = [{

      name = "Traefik ${config.networking.hostName}";
      group = "infrastructure";
      url = "https://traefik-${config.networking.hostName}.${config.mySystem.domain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

  };
}
