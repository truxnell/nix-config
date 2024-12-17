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
    enable = mkEnableOption "system impermanence";
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


  config = lib.mkIf cfg.enable {
    # move ssh keys

    # bind a initrd command to rollback to blank root after boot
   boot.initrd.postDeviceCommands = lib.mkAfter ''
     zfs rollback -r ${cfg.rootPoolName}@${cfg.rootBlankSnapshotName}
   '';

    systemd.tmpfiles.rules = mkIf config.services.openssh.enable [
      # "d /etc/ 0755 root root -" #The - disables automatic cleanup, so the file wont be removed after a period
      # "d /etc/ssh/ 0755 root root -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    environment.persistence."${cfg.persistPath}" = {
      hideMounts = true;
      directories =
        [
          "/var/log" # persist logs between reboots for debugging
          "/var/lib/containers" # cache files (restic, nginx, contaienrs)
          "/var/lib/nixos" # nixos state

        ];
      files = [
        "/etc/machine-id"
        # "/etc/adjtime" # hardware clock adjustment
        # ssh keys
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };

  };
}
