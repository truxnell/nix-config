{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.services.dnsmasq;
  domain = config.networking.domain;
in
{
  options.mySystem.services.dnsmasq.enable = mkEnableOption "dnsmasq";

  config = mkIf cfg.enable {

    sops.secrets = {

      # configure secret for forwarding rules
      "system/networking/bind/trux.dev".sopsFile = ./secrets.sops.yaml;
      "system/networking/bind/trux.dev".mode = "0444"; # This is world-readable but theres nothing security related in the file

      # Restart dnscrypt when secret changes
      "system/networking/bind/trux.dev".restartUnits = [ "bind.service" ];
    };


    services.bind = {

      enable = true;
      zones = [
        {
          name = "trux.dev.";
          master = true;

          file = config.sops.secrets."system/networking/bind/trux.dev".path;
        }
      ];
      extraOptions = ''
        recursion yes;
        dnssec-validation auto;
      '';
      extraConfig = ''
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
      '';
    };

  };
}

