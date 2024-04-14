{ lib
, config
, ...
}:
let
  cfg = config.mySystem.system.impermanence;
in
with lib;
{
  options.mySystem.system.impermanence = {
    rootBlankSnapshotName = lib.mkOption {
      type = lib.types.str;
      default = "blank";
    };
    rootPoolName = lib.mkOption {
      type = lib.types.str;
      default = "rpool/local/root";
    };
    persistPath = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
    };

  };

  config = {

    # move ssh keys
    mySystem.system.impermanence.sshPath = "${cfg.persistPath}/nixos/etc/ssh";
    mySystem.system.impermanence.enable = true;

    # bind a initrd command to rollback to blank root after boot
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r ${cfg.rootPoolName}@${cfg.rootBlankSnapshotName}
    '';

    # move ssh keys to persist folder
    services.openssh.hostKeys = mkIf config.services.openssh.enable [
      {
        path = "${config.mySystem.system.impermanence.sshPath}/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "${config.mySystem.system.impermanence.sshPath}/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];

    # If impermanent, move key location to safe
    systemd.tmpfiles.rules = mkIf config.services.openssh.enable [
      "d ${config.mySystem.system.impermanence.sshPath}/ 0755 root root -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    # set machine id for log continuity
    environment.etc.machine-id.source = "${cfg.persistPath}/nixos/etc/machine-id";

    # keep hardware clock adjustment data
    environment.etc.adjtime.source = "${cfg.persistPath}/nixos/etc/adjtime";

  };

}
