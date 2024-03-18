# Ref: https://nixos.wiki/wiki/Encrypted_DNS#dnscrypt-proxy2
{ inputs
, outputs
, pkgs
, config
, ...
}: {
  # Disable resolvd to ensure it doesnt re-write /etc/resolv.conf
  config.services.resolved.enable = false;

  # Fix this devices DNS resolv.conf else resolvd will point it to dnscrypt
  # causing a risk of no dns if service fails.
  config.networking = {
    nameservers = [ "10.8.10.1" ]; # TODO make varible IP

    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  # configure secret for forwarding rules
  config.sops.secrets."system/networking/dnscrypt-proxy2/forwarding-rules".sopsFile = ./dnscrypt-proxy2.sops.yaml;
  config.sops.secrets."system/networking/dnscrypt-proxy2/forwarding-rules".mode = "0444"; # This is world-readable but theres nothing security related in the file

  # Restart dnscrypt when secret changes
  config.sops.secrets."system/networking/dnscrypt-proxy2/forwarding-rules".restartUnits = [ "dnscrypt-proxy2" ];

  config.services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      require_dnssec = true;
      forwarding_rules = config.sops.secrets."system/networking/dnscrypt-proxy2/forwarding-rules".path;

      server_names = [ "NextDNS-f6fe35" ];

      static = {
        "NextDNS-f6fe35" = {
          stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2Y2ZmUzNQ";
        };
      };
    };
  };
}
