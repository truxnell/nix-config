{ lib, config, pkgs, ... }:
let
  cfg = config.mySystem.services.qbittorrent;
  image = "ghcr.io/buroa/qbtools:v0.15.0@sha256:067a68a0c7b2f522b7527e7bb48cf18614d46c16fcbcd16561d1bbc7f7f983fd";

in
with lib;
{
  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."services/qbittorrent/config.yaml" = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
    };

    systemd.services."qbtools-tag" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
          ${image} \
          tagging  \
          --added-on  \
          --expired  \
          --last-activity  \
          --sites  \
          --unregistered  \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        startAt = "hourly";
      };

    systemd.services."qbtools-prune-orphaned" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
          ${image} \
          prune  \
          --exclude-category  \
          manual \
          --exclude-category \
          uploads \
          --include-tag \
          unregistered \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        startAt = "*-*-* 05:20:00";

      };

    systemd.services."qbtools-prune-expired" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
          ${image} \
          prune  \
          --exclude-category  \
          manual \
          --exclude-category \
          uploads \
          --include-tag \
          expired \
          --exclude-tag \
          activity:24h \
          --exclude-tag \
          permaseed \
          --exclude-tag \
          site:myanonamouse \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        startAt = "*-*-* 05:10:00";

      };

    systemd.services."qbtools-reannounce" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
          ${image} \
          reannounce \
          --process-seeding \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        startAt = "hourly";
      };


  };
}
