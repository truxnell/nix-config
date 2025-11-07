{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.services.nginx;
in
{
  options.mySystem.services.nginx.enable = mkEnableOption "nginx";

  config = mkIf cfg.enable {

    services.nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedBrotliSettings = true;

      proxyResolveWhileRunning = true; # needed to ensure nginx loads even if it cant resolve vhosts

      statusPage = true;
      enableReload = true;

      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

      # Enhanced logging for better log analysis
      commonHttpConfig = ''
        # JSON-formatted access logs for better parsing
        log_format json_combined escape=json
        '{'
          '"time_local":"$time_local",'
          '"remote_addr":"$remote_addr",'
          '"method":"$request_method",'
          '"request_uri":"$request_uri",'
          '"status":$status,'
          '"body_bytes_sent":$body_bytes_sent,'
          '"request_time":$request_time,'
          '"http_referrer":"$http_referer",'
          '"http_user_agent":"$http_user_agent",'
          '"host":"$host",'
          '"upstream_addr":"$upstream_addr",'
          '"upstream_response_time":"$upstream_response_time"'
        '}';
        
        # Use JSON format for access logs
        access_log /var/log/nginx/access.log json_combined;
        
        # Enhanced error logging
        error_log /var/log/nginx/error.log warn;
      '';

      # appendHttpConfig = ''
      #   # Minimize information leaked to other domains
      #   add_header 'Referrer-Policy' 'origin-when-cross-origin';

      #   # Disable embedding as a frame
      #   add_header X-Frame-Options SAMEORIGIN always;

      #   # Prevent injection of code in other mime types (XSS Attacks)
      #   add_header X-Content-Type-Options nosniff;

      # '';
      # # TODO add cloudflre IP's when/if I ingest internally.
      # commonHttpConfig = ''
      #   add_header X-Clacks-Overhead "GNU Terry Pratchett";
      # '';
      # provide default host with returning error
      # else nginx returns the first server
      # in the config file... >:S
      virtualHosts = {
        "_" = {
          default = true;
          forceSSL = true;
          useACMEHost = config.networking.domain;
          extraConfig = "return 444;";
        };
      };

    };

    networking.firewall = {

      allowedTCPPorts = [
        80
        443
      ];
      allowedUDPPorts = [
        80
        443
      ];
    };

    # required for using acme certs
    users.users.nginx.extraGroups = [ "acme" ];

  };
}
