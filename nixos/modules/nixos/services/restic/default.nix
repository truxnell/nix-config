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

      services.restic_nightly_snapshot = {
        description = "Nightly ZFS snapshot for Restic";
        path = with pkgs; [ zfs ];
        serviceConfig.Type = "simple";
        script = ''
          zfs destroy rpool/safe/persist@restic_nightly_snap || true && \
          zfs snapshot rpool/safe/persist@restic_nightly_snap
        '';
      };

    };
  };
}
