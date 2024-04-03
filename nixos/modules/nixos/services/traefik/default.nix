{ lib
, config
, pkgs
, ...
}:
# ref: https://github.com/rishid/nix-config/blob/be0d5cbbe4df79ed2b2ba4714456f21777c72b38/modules/traefik/default.nix#L170
with lib;
let
  cfg = config.mySystem.services.traefik;
in
{
  options.mySystem.services.traefik.enable = mkEnableOption "Traefik reverse proxy";

  # TODO add to homepage
  # modules.homepage.infrastructure-services = [{
  #   Traefik = {
  #     icon = "traefik.svg";
  #     description = "Reverse proxy";
  #     href = "https://traefik.dhupar.xyz:444";
  #   };
  # }];

  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.traefik = {
      enable = true;

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
        serversTransport.insecureSkipVerify = true; # TODO should this be per service?

        providers.docker = {
          # endpoint = "unix:///var/run/docker.sock";
          endpoint = "tcp://127.0.0.1:2375";
          exposedByDefault = false;
          defaultRule = "Host(`{{ normalize .Name }}.${config.networking.domain}`)";
          # network = "proxy";
        };

        # Listen on port 80 and redirect to port 443
        entryPoints.web = {
          address = ":80";
          http.redirections.entrypoint.to = "websecure";
        };

        # Run everything SSL
        # entryPoints.websecure = {
        #   address = ":444";
        #   http = {
        #     tls = {
        #       certresolver = "letsencrypt";
        #       domains.main = "${config.networking.domain}";
        #       domains.sans = "*.${config.networking.domain}";
        #     };
        #   };
        #   http3 = { };
        # };

        #   certificatesResolvers.letsencrypt.acme = {
        #     dnsChallenge.provider = "cloudflare";
        #     email = "${hostName}@${domain}";
        #     keyType = "EC256";
        #     storage = "${config.services.traefik.dataDir}/acme.json";
        #   };
        # };
      };
      # Dynamic configuration
      dynamicConfigOptions = {

        http.middlewares = {
          # Whitelist local network and VPN addresses
          local-only.ipWhiteList.sourceRange = [
            "127.0.0.1/32" # localhost
            "192.168.0.0/16" # RFC1918
            "10.0.0.0/8" # RFC1918
            "172.16.0.0/12" # RFC1918 (docker network)
            "100.64.0.0/10" # Tailscale network
          ];

          authelia = {
            # Forward requests w/ middlewares=authelia@file to authelia.
            forwardAuth = {
              # address = cfg.autheliaUrl;
              address = "http://localhost:9092/api/verify?rd=https://auth.dhupar.xyz:444/";
              trustForwardHeader = true;
              authResponseHeaders = [
                "Remote-User"
                "Remote-Name"
                "Remote-Email"
                "Remote-Groups"
              ];
            };
          };
          authelia-basic = {
            # Forward requests w/ middlewares=authelia-basic@file to authelia.
            forwardAuth = {
              address = "http://localhost:9092/api/verify?auth=basic";
              trustForwardHeader = true;
              authResponseHeaders = [
                "Remote-User"
                "Remote-Name"
                "Remote-Email"
                "Remote-Groups"
              ];
            };
          };
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

        middlewares.compress.compress = { };
        tls.options.default = {
          minVersion = "VersionTLS13";
          sniStrict = true;
        };

        # Set up wildcard domain certificates for both *.hostname.domain and *.local.domain
        # http.routers = {
        #   traefik = {
        #     entrypoints = "websecure";
        #     rule = "Host(`traefik.${domain}`)";
        #     tls.certresolver = "letsencrypt";
        #     tls.domains = [{
        #       main = "${domain}";
        #       sans = "*.${domain}";
        #     }];
        #     middlewares = "authelia@file";
        #     service = "api@internal";
        #   };

        # };

      };
    };
  };
}
