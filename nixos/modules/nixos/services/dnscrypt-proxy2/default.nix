{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.services.dnscrypt-proxy;
in
{
  options.mySystem.services.dnscrypt-proxy.enable = mkEnableOption "Cloudflare ddns";

  config = mkIf cfg.enable {
    # Disable resolvd to ensure it doesnt re-write /etc/resolv.conf
    services.resolved.enable = false;

    # Fix this devices DNS resolv.conf else resolvd will point it to dnscrypt
    # causing a risk of no dns if service fails.
    networking = {
      nameservers = [ "10.8.10.1" ]; # TODO make varible IP
      firewall.allowedTCPPorts = [ 53 ];
      firewall.allowedUDPPorts = [ 53 ];

      dhcpcd.extraConfig = "nohook resolv.conf";
    };
    sops.secrets = {

      # configure secret for forwarding rules
      "system/networking/dnscrypt-proxy2/forwarding-rules".sopsFile = ./dnscrypt-proxy2.sops.yaml;
      "system/networking/dnscrypt-proxy2/forwarding-rules".mode = "0444"; # This is world-readable but theres nothing security related in the file

      # Restart dnscrypt when secret changes
      "system/networking/dnscrypt-proxy2/forwarding-rules".restartUnits = [ "dnscrypt-proxy2.service" ];
    };

    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        require_dnssec = true;
        forwarding_rules = config.sops.secrets."system/networking/dnscrypt-proxy2/forwarding-rules".path;
        listen_addresses = [ "0.0.0.0:53" ];
        server_names = [ "NextDNS" ];

        static = {
          "NextDNS" = {
            stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2Y2ZmUzNQ";
          };
        };
      };
    };
  };
}
