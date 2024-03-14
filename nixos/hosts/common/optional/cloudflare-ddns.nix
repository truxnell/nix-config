{ inputs, outputs, config, ... }: {

  # Cloudflare dynamic dns to keep my DNS records pointed at home
  services.cloudflare-dyndns.enable = true;
  
}