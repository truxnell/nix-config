{
  imports = [
    ./monitoring.nix
    ./reboot-required-check.nix
    ./cloudflare-dyndns
    ./maddy
    ./dnscrypt-proxy2
    ./cockpit
    ./podman
    ./traefik
    ./nfs
    ./nix-serve
    ./glances
    ./syncthing
    ./restic
    ./powerdns
    ./adguardhome
    ./mosquitto
    ./zigbee2mqtt
    ./postgresql
    ./blocky
    ./openvscode-server
    ./grafana
    ./prometheus
    ./radicale
    ./node-red
    ./nginx
    ./miniflux
    ./calibre-web
  ];
}
