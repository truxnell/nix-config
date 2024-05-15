{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.system.resticBackup;
in
{
  options.mySystem.system.resticBackup = {
    local = {
      enable = mkEnableOption "Local backups" // { default = true; };
      location = mkOption
        {
          type = types.str;
          description = "Location for local backups";
          default = "";
        };
    };
    remote = {
      enable = mkEnableOption "Remote backups" // { default = true; };
      location = mkOption
        {
          type = types.str;
          description = "Location for remote backups";
          default = "";
        };
    };
    mountPath = mkOption
      {
        type = types.str;
        description = "Location for  snapshot mount";
        default = "/mnt/nightly_backup";
      };

  };


  config = {

    # Warn if backups are disable and machine isnt a dev box
    warnings = [
      (mkIf (!cfg.local.enable && config.mySystem.purpose != "Development") "WARNING: Local backups are disabled!")
      (mkIf (!cfg.remote.enable && config.mySystem.purpose != "Development") "WARNING: Remote backups are disabled!")
    ];

    sops.secrets = mkIf (cfg.local.enable || cfg.remote.enable) {
      "services/restic/password" = {
        sopsFile = ./secrets.sops.yaml;
        owner = "kah";
        group = "kah";
      };

      "services/restic/env" = {
        sopsFile = ./secrets.sops.yaml;
        owner = "kah";
        group = "kah";
      };
    };


    # useful commands:
    # view snapshots - zfs list -t snapshot

    # below takes a snapshot of the zfs persist volume
    # ready for restic syncs
    # essentially its a nightly rotation of atomic state at 2am.

    # this is the safest option, as if you run restic
    # on live services/databases/etc, you will have
    # a bad day when you try and restore
    # (backing up a in-use file can and will cause corruption)

    # ref: https://cyounkins.medium.com/correct-backups-require-filesystem-snapshots-23062e2e7a15
    systemd = mkIf (cfg.local.enable || cfg.remote.enable) {

      timers.restic_nightly_snapshot = {
        description = "Nightly ZFS snapshot timer";
        wantedBy = [ "timers.target" ];
        partOf = [ "restic_nightly_snapshot.service" ];
        timerConfig.OnCalendar = "2:00";
        timerConfig.Persistent = "true";
      };

      # recreate snapshot and mount, ready for backup
      # I used mkdir -p over a nix tmpfile, as mkdir -p exits cleanly
      # if the folder already exists, and tmpfiles complain
      # if the folder exists and is already mounted.
      services.restic_nightly_snapshot = {
        description = "Nightly ZFS snapshot for Restic";
        path = with pkgs; [ zfs busybox ];
        serviceConfig.Type = "simple";
        script = ''
          mkdir -p /mnt/nightly_backup/ && \
          umount ${cfg.mountPath} || true && \
          zfs destroy rpool/safe/persist@restic_nightly_snap || true && \
          zfs snapshot rpool/safe/persist@restic_nightly_snap && \
          mount -t zfs rpool/safe/persist@restic_nightly_snap ${cfg.mountPath}
        '';
      };


    };
  };
}
