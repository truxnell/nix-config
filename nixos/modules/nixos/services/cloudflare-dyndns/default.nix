{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.services.cfDdns;
in
{
  options.mySystem.services.cfDdns.enable = mkEnableOption "Cloudflare ddns";

  config = mkIf cfg.enable {
    # Current nixpkgs cf-ddns only supports using a env file for the apitoken
    # but not for domains, which makes them hard to find.
    # To circumvent this, I put both in the 'apiTokenFile' var
    # so my secret is:

    # apiTokenFile: |-
    #   CLOUDFLARE_API_TOKEN=derp
    #   CLOUDFLARE_DOMAINS=derp.herp.xyz derp1.herp.xyz

    # TODO add notifications on IP change
    # init secret
    sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".sopsFile = ./cloudflare-dyndns.sops.yaml;

    # Restart when secret changes
    sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".restartUnits = [ "cloudflare-dyndns.service" ];

    networking.firewall = {
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };

    # Cloudflare dynamic dns to keep my DNS records pointed at home
    services.cloudflare-dyndns = {
      enable = true;
      ipv6 = false;
      proxied = true;
      apiTokenFile = config.sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".path;
      domains = [ ];
    };
  };
}
