{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.services.bind;
  inherit (config.networking) domain;
in
{
  options.mySystem.services.bind.enable = mkEnableOption "bind";

  config = mkIf cfg.enable {

    sops.secrets = {

      # configure secret for forwarding rules
      "system/networking/bind/trux.dev".sopsFile = ./secrets.sops.yaml;
      "system/networking/bind/trux.dev".mode = "0444"; # This is world-readable but theres nothing security related in the file

      # Restart dnscrypt when secret changes
      "system/networking/bind/trux.dev".restartUnits = [ "bind.service" ];
    };

    networking.resolvconf.useLocalResolver = mkForce false;

    services.bind = {

      enable = true;

      # Ended up having to do the cfg manually
      # to bind the port 5353
      configFile = builtins.toFile "bind.cfg" ''
        include "/etc/bind/rndc.key";
        controls {
          inet 127.0.0.1 allow {localhost;} keys {"rndc-key";};
        };

        acl cachenetworks {  10.8.10.0/24;  10.8.20.0/24;  10.8.30.0/24;  10.8.40.0/24;  };
        acl badnetworks {  };

        options {
          listen-on port 5353 { any; };
          listen-on-v6 port 5353 { ::1; };
          allow-query { cachenetworks; };
          blackhole { badnetworks; };
          forward first;
          forwarders {  10.8.10.1;  };
          directory "/run/named";
          pid-file "/run/named/named.pid";
        recursion yes;
        dnssec-validation auto;

        };

        logging {
          channel stdout {
            stderr;
            severity info;
            print-category yes;
            print-severity yes;
            print-time yes;
          };
          category security { stdout; };
          category dnssec   { stdout; };
          category default  { stdout; };
        };
        acl "trusted" {
          10.8.10.0/24;    # LAN
          10.8.12.0/24;    # TRUSTED
          10.8.20.0/24;    # SERVERS
          10.8.30.0/24;    # IOT
          10.8.40.0/24;    # KIDS
          10.8.50.0/24;    # VIDEO
          10.8.60.0/24;    # VIDEO
          10.8.11.0/24;   # WIREGUARD
          10.5.0.0/24;    # CONTAINERS
        };


        zone "trux.dev." {
          type master;
          file "${config.sops.secrets."system/networking/bind/trux.dev".path}";
          allow-transfer {

        };

          allow-query { any; };

        };

      '';

    };

  };
}
