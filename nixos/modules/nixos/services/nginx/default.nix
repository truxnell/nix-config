{ lib
, config
, pkgs
, ...
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

      appendHttpConfig = ''
        # Add default server as default NGINX behaviour
        # is to serve the first serverblock if no default is
        # set
        server {
          server_name = _;
          listen 80 default_server;
          return 404;
        }
        # Minimize information leaked to other domains
        add_header 'Referrer-Policy' 'origin-when-cross-origin';

        # Disable embedding as a frame
        add_header X-Frame-Options DENY;

        # Prevent injection of code in other mime types (XSS Attacks)
        add_header X-Content-Type-Options nosniff;


      '';
      # TODO add cloudflre IP's when/if I ingest internally.
      commonHttpConfig = ''
        add_header X-Clacks-Overhead "GNU Terry Pratchett";
      '';

    };


    networking.firewall = {

      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 80 443 ];
    };

    # required for using acme certs
    users.users.nginx.extraGroups = [ "acme" ];

  };
}
