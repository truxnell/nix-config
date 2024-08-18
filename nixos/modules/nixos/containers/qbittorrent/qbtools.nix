{ lib, config, pkgs, ... }:
let
  cfg = config.mySystem.services.qbittorrent;
  image = "ghcr.io/buroa/qbtools:v0.15.4@sha256:51c454cdf95e216a8f40ec5744ecbd8f29a924b4aada805fee64beb0b89cbe59";

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
        requires = [ "podman-qbittorrent.service" ];
        startAt = "hourly";
      };

    # systemd.services."qbtools-prune-orphaned" =

    #   {
    #     script = ''
    #       ${pkgs.podman}/bin/podman run --rm \
    #       -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
    #       ${image} \
    #       prune  \
    #       --exclude-category  \
    #       manual \
    #       --exclude-category  \
    #       lts \
    #       --exclude-category \
    #       uploads \
    #       --include-tag \
    #       unregistered \
    #       --server https://qbittorrent.trux.dev  \
    #       --port 443  \
    #       --config /config/config.yaml
    #     '';
    #     path = [ pkgs.podman ];
    #     requires = [ "podman-qbittorrent.service" ];
    #     startAt = "*-*-* 05:20:00";

    #   };

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
          --exclude-category \
          lts \
          --include-tag \
          expired \
          --exclude-tag \
          activity:24h \
          --exclude-tag \
          permaseed \
          --exclude-tag \
          lts \
          --exclude-tag \
          site:myanonamouse \
          --exclude-tag \
          site:orpheus \
          --exclude-tag \
          site:redacted \
          --exclude-tag \
          site:beyond-hd \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "*-*-* 05:10:00";

      };

    systemd.services."qbtools-orphaned" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/qbittorrent/config.yaml".path}:/config/config.yaml \
          -v /tank//natflix/downloads/qbittorrent:/tank/natflix/downloads/qbittorrent:rw \
          ${image} \
          orphaned \
          --exclude-pattern \
          *_unpackerred \
          --exclude-pattern \
          */manual/* \
          --exclude-pattern \
          */uploads/* \
          --server https://qbittorrent.trux.dev  \
          --port 443  \
          --config /config/config.yaml
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "daily";
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
        requires = [ "podman-qbittorrent.service" ];
        startAt = "hourly";
      };


  };
}
