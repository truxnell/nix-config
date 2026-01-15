{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "qbit-tqm";
  category = "services";
  description = "qbit tag manager";
  image = "ghcr.io/home-operations/tqm:1.19.0@sha256:025ee0c0c8b75f4c7bffa90216eedb494b9884e092a47e9c49824fe63427808c"; # string
  group = "568"; # string #int
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };

  };

  config = mkIf cfg.enable {

    ## Secrets
    sops.secrets."services/tqm/config.yaml" = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kah.name;
      inherit (config.users.users.kah) group;
      mode = "0444";
    };

    systemd.services."tqm-qb-tag" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/tqm/config.yaml".path}:/.config/tqm/config.yaml \
          -v /tank/natflix/downloads/qbittorrent/:/tank/natflix/downloads/qbittorrent/ \
          ${image} \
          retag qb
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "hourly";
      };

    systemd.services."tqm-qb-lts-tag" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/tqm/config.yaml".path}:/.config/tqm/config.yaml \
          -v /tank/natflix/downloads/qbittorrent-lts/:/tank/natflix/downloads/qbittorrent/ \
          -v /tank/natflix/i486/:/tank/natflix/i486/ \
          ${image} \
          retag qb-lts
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "hourly";
      };

    systemd.services."tqm-qb-clean" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/tqm/config.yaml".path}:/.config/tqm/config.yaml \
          -v /tank/natflix/downloads/qbittorrent/:/tank/natflix/downloads/qbittorrent/ \
          ${image} \
          clean qb
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "daily";
      };

    systemd.services."tqm-qb-orphan" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          -v ${config.sops.secrets."services/tqm/config.yaml".path}:/.config/tqm/config.yaml \
          -v /tank/natflix/downloads/qbittorrent/:/tank/natflix/downloads/qbittorrent/ \
          ${image} \
          orphan qb
        '';
        path = [ pkgs.podman ];
        requires = [ "podman-qbittorrent.service" ];
        startAt = "daily";
      };

  };

}
