{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.adguardhome;
  app = "adguard-home";
  yaml_schema_version=23;
  port = 53;
  port_webui = 3000;
in
{
  options.mySystem.services.adguardhome = {
    enable = mkEnableOption "Adguard Home";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
    openFirewall = mkEnableOption "Open firewall for ${app}" // {
      default = true;
    };
  };

  config = mkIf cfg.enable  {


        # Warn if backups are disable and machine isnt a dev box
    warnings = mkIf (yaml_schema_version != pkgs.adguardhome.schema_version) [ "WARNING: Adguard upstream YAML schema is version ${builtins.toString pkgs.adguardhome.schema_version}, this config is set to ${builtins.toString config.services.adguardhome.settings.schema_version}"];

    sops.secrets = {
      "system/networking/bind/trux.dev".sopsFile = ./secrets.sops.yaml;
      "system/networking/bind/trux.dev".restartUnits = [ "bind.service" ];
    };

      services.adguardhome = {
        enable = true;

        mutableSettings = false;
        settings = {
          bind_host = "0.0.0.0";
          bind_port = port_webui;
          schema_version=yaml_schema_version; # Just to be cautious, defualt is pkgs.adguardhome.schema_version.

          auth_attempts = 3;
          block_auth_min = 3600;

          dns = {
            # dns server bind deets
            bind_host = "127.0.0.1";
            port = port;

            # bootstrap DNS - used for resolving upstream dns deets
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

            # upstream DNS
            upstream_dns = [
              # split brain dns - forward to local powerdns
              "[/trux.dev/]127.0.0.1:5353"
              "[/natallan.com/]127.0.0.1:5353"

              # resolve fqdn for local ip's
              "[/l.voltaicforge.com/]10.8.10.1"

              # reverse dns setup
              "[/in-addr.arpa/]10.8.10.1" # reverse dns lookup to UDMP
              "[/ip6.arpa/]10.8.10.1" # reverse dns lookup to UDMP

              # primary dns - quad9
              "https://dns10.quad9.net/dns-query"

            ];
            upstream_mode = "load_balance";

            # fallback dns - cloudflare and mullvad
            fallback_dns = [
              "https://dns.cloudflare.com/dns-query"
              "https://doh.mullvad.net/dns-query"
            ];

            # resolving local addresses
            local_ptr_upstreams = [ "10.8.10.1" ]; # UDMP router
            use_private_ptr_resolvers = true;

            # security
            enable_dnssec = true;

            # local cache settings
            cache_size = 100000000; # 100MB - unnessecary but hey
            cache_ttl_min = 60;
            cache_optimistic = true;

            theme = "auto";
          };


          filters = [
            {
              # AdGuard Base filter, Social media filter, Spyware filter, Mobile ads filter, EasyList and EasyPrivacy
              enabled = true;
              id = 1;
              name = "AdGuard DNS filter";
              url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
            }
            {
              # AdAway default blocklist
              enabled = true;
              id = 2;
              name = "AdAway Default Blocklist";
              url = "https://adaway.org/hosts.txt";
            }
            {
              # Big OSID
              enabled = true;
              id = 3;
              name = "Big OSID";
              url = "https://big.oisd.nl";
            }
            {
              # 1Hosts Lite
              enabled = true;
              id = 4;
              name = "1Hosts Lite";
              url = "https://o0.pages.dev/Lite/adblock.txt";
            }
            {
              # HAGEZI Multi Pro
              enabled = true;
              id = 4;
              name = "hagezi multi pro";
              url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt";
            }



          ];
        };
      };

      networking.firewall = mkIf cfg.openFirewall {

        allowedTCPPorts = [ port port_webui ];
        allowedUDPPorts = [ port port_webui ];

      };

      mySystem.services.gatus.monitors = [
        {
          name = "${config.networking.hostName} external dns";
          group = "dns";
          url = "${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString port}";
          dns = {
            query-name = "cloudflare.com";
            query-type = "A";
          };
          interval = "1m";
          alerts = [{ type = "pushover"; }];
          conditions = [ "[DNS_RCODE] == NOERROR" ];
        }
        {
          name = "${config.networking.hostName} internal dns";
          group = "dns";
          url = "${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString port}";
          dns = {
            query-name = "unifi.${config.mySystem.internalDomain}";
            query-type = "A";
          };
          interval = "1m";
          alerts = [{ type = "pushover"; }];
          conditions = [ "[DNS_RCODE] == NOERROR" ];
        }
      ];

      mySystem.services.homepage.infrastructure-services = mkIf cfg.addToHomepage [
        {
          "Adguard ${config.networking.hostName}" = {
            icon = "${app}.svg";
            href = "http://${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString port_webui}";
            description = "DNS Ad blocking";
            container = "Infrastructure";
            widget =
              {
                type = "adguard";
                url = "http://${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString port_webui}";
                # username = "";
                # password = "";
              };
          };
        }
      ];


    };

}
