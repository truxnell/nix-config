{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.blocky;
in
{
  options.mySystem.services.blocky.enable = mkEnableOption "blocky";

  config = mkIf cfg.enable {

    services.blocky = {
      enable = true;
      settings = {

        # optional: use black and white lists to block queries (for example ads, trackers, adult pages etc.)
        blocking = {
          # definition of blacklist groups. Can be external link (http/https) or local file
          blackLists = {
            ads = [


              "https://blocklistproject.github.io/Lists/ads.txt"

            ];
            malicious = [
              "https://blocklistproject.github.io/Lists/adguard/malware-ags.txt"

            ];
            adult = [
              "https://blocklistproject.github.io/Lists/adguard/porn-ags.txt"
            ];

            void = [ ];
          };
          # definition of whitelist groups. Attention: if the same group has black and whitelists, whitelists will be used to disable particular blacklist entries. If a group has only whitelist entries -> this means only domains from this list are allowed, all other domains will be blocked
          whiteLists.ads = [ ];
          # definition: which groups should be applied for which client
          clientGroupsBlock = {
            # default will be used, if no special definition for a client name exists
            default = [ "ads" "malicious" ];
            # use client name (with wildcard support: * - sequence of any characters, [0-9] - range)
            # or single ip address / client subnet as CIDR notation
            # "foo*" = [ "ads" ];
            "10.8.10.40/24" = [ "ads" "malicioous" "adult" ];
          };

          # which response will be sent, if query is blocked:
          # zeroIp: 0.0.0.0 will be returned (default)
          # nxDomain: return NXDOMAIN as return code
          # comma separated list of destination IP addresses (for example: 192.100.100.15, 2001:0db8:85a3:08d3:1319:8a2e:0370:7344). Should contain ipv4 and ipv6 to cover all query types. Useful with running web server on this address to display the "blocked" page.
          blockType = "zeroIp";
          # optional: TTL for answers to blocked domains
          # default: 6h
          blockTTL = "6h";

          loading = {
            # optional: automatically list refresh period (in duration format). Default: 4h.
            # Negative value -> deactivate automatically refresh.
            # 0 value -> use default
            refreshPeriod = "4h";

            # optional: if failOnError, application startup will fail if at least one list can't be downloaded / opened. Default: blocking
            strategy = "fast";

            downloads = {
              # optional: timeout for list download (each url). Default: 60s. Use large values for big lists or slow internet connections
              timeout = "60s";
              # optional: Number of download attempts.
              attempts = 5;
              # optional: Time between the download attempts. Default: 1s
              cooldown = "1s";
            };
          };
        };

        # optional: use these DNS servers to resolve blacklist urls and upstream DNS servers. It is useful if no system DNS resolver is configured, and/or to encrypt the bootstrap queries.
        bootstrapDns = [
          {
            upstream = "https://one.one.one.one/dns-query";
            ips = [ "1.1.1.1" "1.0.0.1" ];
          }
          {
            upstream = "https://dns.quad9.net/dns-query";
            ips = [ "9.9.9.9" "149.112.112.112" ];
          }
        ];
        # optional: configuration for caching of DNS responses
        caching = {
          # duration how long a response must be cached (min value).
          # If <=0, use response's TTL, if >0 use this value, if TTL is smaller
          # Default: 0
          minTime = "0m";
          # duration how long a response must be cached (max value).
          # If <0, do not cache responses
          # If 0, use TTL
          # If > 0, use this value, if TTL is greater
          # Default: 0
          maxTime = "0m";
          # Max number of cache entries (responses) to be kept in cache (soft limit). Useful on systems with limited amount of RAM.
          # Default (0): unlimited
          maxItemsCount = 0;
          # if true, will preload DNS results for often used queries (default: names queried more than 5 times in a 2-hour time window)
          # this improves the response time for often used queries, but significantly increases external traffic
          # default: false
          prefetching = true;
          # prefetch track time window (in duration format)
          # default: 120
          prefetchExpires = "2h";
          # name queries threshold for prefetch
          # default: 5
          prefetchThreshold = 5;
          # Max number of domains to be kept in cache for prefetching (soft limit). Useful on systems with limited amount of RAM.
          # Default (0): unlimited
          prefetchMaxItemsCount = 0;
          # Time how long negative results (NXDOMAIN response or empty result) are cached. A value of -1 will disable caching for negative results.
          # Default: 30m
          cacheTimeNegative = "90m";
        };

        # optional: Determines how blocky will create outgoing connections. This impacts both upstreams, and lists.
        # accepted: dual, v4, v6
        # default: dual
        connectIPVersion = "v4";

        # optional: custom IP address(es) for domain name (with all sub-domains). Multiple addresses must be separated by a comma
        # example: query "printer.local" or "my.printer.local" will return 192.168.178.3
        customDNS = {
          customTTL = "1h";
          # optional: if true (default), return empty result for unmapped query types (for example TXT, MX or AAAA if only IPv4 address is defined).
          # if false, queries with unmapped types will be forwarded to the upstream resolver
          filterUnmappedTypes = false;
          # optional: replace domain in the query with other domain before resolver lookup in the mapping
          # mapping = [ ];
        };
        # conditional = {
        #   fallbackUpstream = false;
        #   mapping = {
        #     "trux.dev" = "127.0.0.1:5353";

        #     # resolve fqdn for local ip's
        #     "l.voltaicforge.com" = "10.8.10.1";

        #     # reverse dns setup
        #     "in-addr.arpa" = "10.8.10.1"; # reverse dns lookup to UDMP
        #     "ip6.arpa" = "10.8.10.1"; # reverse dns lookup to UDMP
        #   };
        # };
        # optional: drop all queries with following query types. Default: empty
        filtering.queryTypes = [ "AAAA" ];

        # optional: logging configuration
        log = {
          # optional: Log level (one from debug, info, warn, error). Default: info
          level = "info";
          # optional: Log format (text or json). Default: text
          format = "text";
          # optional: log timestamps. Default: true
          timestamp = true;
          # optional: obfuscate log output (replace all alphanumeric characters with *) for user sensitive data like request domains or responses to increase privacy. Default: false
          privacy = false;
        };

        # optional: Minimal TLS version that the DoH and DoT server will use
        minTlsServeVersion = "1.2";
        # if https port > 0: path to cert and key file for SSL encryption. if not set, self-signed certificate will be generated
        #certFile: server.crt
        #keyFile: server.key

        # optional: ports configuration
        ports = {
          # optional: DNS listener port(s) and bind ip address(es), default 53 (UDP and TCP). Example: 53, :53, "127.0.0.1:5353,[::1]:5353"
          dns = 53;
          # optional: Port(s) and bind ip address(es) for DoT (DNS-over-TLS) listener. Example: 853, 127.0.0.1:853
          tls = 853;
          # optional: Port(s) and optional bind ip address(es) to serve HTTPS used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:443. Example: 443, :443, 127.0.0.1:443,[::1]:443
          https = 8443;
          # optional: Port(s) and optional bind ip address(es) to serve HTTP used for prometheus metrics, pprof, REST API, DoH... If you wish to specify a specific IP, you can do so such as 192.168.0.1:4000. Example: 4000, :4000, 127.0.0.1:4000,[::1]:4000
          http = 4000;
        };

        # optional: configuration for prometheus metrics endpoint
        prometheus = {
          # enabled if true
          enable = true;
          # url path, optional (default '/metrics')
          path = "/metrics";
        };

        # optional: If true, blocky will fail to start unless at least one upstream server per group is reachable. Default: false
        startVerifyUpstream = true;

        upstreams = {
          groups = {
            # these external DNS resolvers will be used. Blocky picks 2 random resolvers from the list for each query
            # format for resolver: [net:]host:[port][/path]. net could be empty (default, shortcut for tcp+udp), tcp+udp, tcp, udp, tcp-tls or https (DoH). If port is empty, default port will be used (53 for udp and tcp, 853 for tcp-tls, 443 for https (Doh))
            # this configuration is mandatory, please define at least one external DNS resolver
            default = [
              "https://dns10.quad9.net/dns-query"
              "https://dns.cloudflare.com/dns-query"
              "https://doh.mullvad.net/dns-query"
            ];

            # optional: use client name (with wildcard support: * - sequence of any characters, [0-9] - range)
            # or single ip address / client subnet as CIDR notation
            "10.8.50.1/24" = [ "https://cloudflare-dns.com/dns-query" ];
          };
          # Blocky supports different upstream strategies (default parallel_best) that determine how and to which upstream DNS servers requests are forwarded.
          strategy = "parallel_best";

          # optional: timeout to query the upstream resolver. Default: 2s
          timeout = "2s";
        };
      };
    };

  };
}
