{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "qbit-tqm";
  category = "services";
  description = "qbit tag manager";
  image = "ghcr.io/home-operations/tqm:1.17.0@sha256:05b62239063ad1e884f2254532e3dc9b60cff08870112dca244af328d761be0d";
  user = "568"; #string
  group = "568"; #string
  port = 0; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;
        };
      prometheus = mkOption
        {
          type = lib.types.bool;
          description = "Enable prometheus scraping";
          default = true;
        };
      addToDNS = mkOption
        {
          type = lib.types.bool;
          description = "Add to DNS list";
          default = true;
        };
      dev = mkOption
        {
          type = lib.types.bool;
          description = "Development instance";
          default = false;
        };
      backup = mkOption
        {
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
