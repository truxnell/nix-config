{
  imports = [
    ./monitoring.nix
    ./reboot-required-check.nix
    ./cloudflare-dyndns
    ./maddy
    ./dnscrypt-proxy2
    ./cockpit
    ./podman
  ];
}
