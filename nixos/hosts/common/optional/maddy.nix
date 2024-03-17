{ inputs, outputs, config, ... }: {

  # init secret
  config.sops.secrets."system/networking/dcloudflare-dyndns/apiTokenFile".sopsFile = ./cloudflare-dyndns.sops.yaml;
  config.sops.secrets."system/networking/dcloudflare-dyndns/domains".sopsFile = ./cloudflare-dyndns.sops.yaml;

  # Cloudflare dynamic dns to keep my DNS records pointed at home
  services.maddy = {
    enable = true;
    ipv6 = false;
    proxied = true;
    apiTokenFile = config.secret.sops."system/networking/dcloudflare-dyndns/apiTokenFile".path;
    domains = config.secret.sops."system/networking/dcloudflare-dyndns/domains".path;
  };

}
