# Ref: https://nixos.wiki/wiki/Encrypted_DNS#dnscrypt-proxy2

{ inputs, outputs, pkgs, config, ... }: {

  # Disable resolvd to ensure it doesnt re-write /etc/resolv.conf
  services.resolved.enable = false;
  
  # Fix this devices DNS resolv.conf
  networking = {
    nameservers = [ "10.8.10.1" ];
    
    dhcpcd.extraConfig = "nohook resolv.conf";
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
        require_dnssec = true;

        forwarding_rules = pkgs.writeText "forwarding-rules.txt" ''
          natallan.com 10.8.10.1
          sonarr.trux.dev 10.8.20.11
          radarr.trux.dev 10.8.20.11
          lidarr.trux.dev 10.8.20.11
          qbittorrent.trux.dev 10.8.20.11
          qbittorrent-lidarr.trux.dev 10.8.20.11
          syncthing.trux.dev 10.8.20.11
          qbittorrent-readarr.trux.dev 10.8.20.11
          filebrowser.trux.dev 10.8.20.11
          minio.trux.dev 10.8.20.11
          sabnzbd.trux.dev 10.8.20.11
          trux.dev   10.8.20.203
        '';
 
         server_names = ["NextDNS-f6fe35"];
 
         static = { 
            "NextDNS-f6fe35" = {
            stamp = "sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2Y2ZmUzNQ";
          };
        };
    };
  };
}
