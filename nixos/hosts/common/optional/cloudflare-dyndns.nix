{ config
, lib
, ...
}: {
  # Current nixpkgs cf-ddns only supports using a env file for the apitoken
  # but not for domains, which makes them hard to find.
  # To circumvent this, I put both in the 'apiTokenFile' var
  # so my secret is:

  # apiTokenFile: |-
  #   CLOUDFLARE_API_TOKEN=derp
  #   CLOUDFLARE_DOMAINS=derp.herp.xyz derp1.herp.xyz

  # init secret
  config.sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".sopsFile = ./cloudflare-dyndns.sops.yaml;

  # Restart when secret changes
  config.sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".restartUnits = [ "cloudflare-dyndns" ];

  # Cloudflare dynamic dns to keep my DNS records pointed at home
  config.services.cloudflare-dyndns = {
    enable = true;
    ipv6 = false;
    proxied = true;
    apiTokenFile = config.sops.secrets."system/networking/cloudflare-dyndns/apiTokenFile".path;
    domains = [ ];
  };
}
