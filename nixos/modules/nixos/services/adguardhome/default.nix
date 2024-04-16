{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.adguardhome;
  port = 53;
  port_webui = 3000;
in
{
  options.mySystem.services.adguardhome = {
    enable = mkEnableOption "Adguard Home";
    openFirewall = mkEnableOption "Open firewall for ${app}" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {

    services.adguardhome = {
      enable = true;

      mutableSettings = false;
      settings = {
        bind_host = "0.0.0.0";
        bind_port = port_webui;
        auth_attempts = 3;
        block_auth_min = 3600;
        dns = {
          bind_host = "127.0.0.1";
          port = port;
          upstream_dns = [
            "https://dns10.quad9.net/dns-query"
            "https://doh.mullvad.net/dns-query"
          ];
          fallback_dns = [ "https://dns.cloudflare.com/dns-query" ];
          bootstrap_dns = [
            # quad9
            "9.9.9.10"
            "149.112.112.10"
            "2620:fe::10"
            "2620:fe::fe:10"
            # cloudflare
            "1.1.1.1"
            "2606:4700:4700::1111"
          ];
          upstream_mode = "load_balance";
          cache_size = 4194304;
          cache_ttl_min = 60;
          cache_optimistic = true;
          use_private_ptr_resolvers = true;
          local_ptr_upstreams = [ "localhost:5353" ];

          rewrites = [{
            domain = "*.${config.networking.domain}";
            answer = "10.8.10.1"; # UDMP router
          }];

          filters = [
            {
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
              enabled = true;
            }
            {
              name = "AdAway Default Blocklist";
              url = "https://adaway.org/hosts.txt";
              enabled = true;
            }
            {
              name = "OISD (Big)";
              url = "https://big.oisd.nl";
              enabled = true;
            }
          ];
        };
      };
    };

    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ port port_webui ];
      allowedUDPPorts = [ port port_webui ];

    };

  };
}
