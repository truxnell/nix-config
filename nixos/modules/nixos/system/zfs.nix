{ lib
, config
, ...
}:
let
  cfg = config.mySystem.system.zfs;
in
with lib;
{
  options.mySystem.system.zfs = {
    enable = mkEnableOption "zfs";
    mountPoolsAtBoot = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    impermanenceRollback = mkEnableOption "Rollback root on boot for impermance";

  };

  config = mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        forceImportRoot = false;
        extraPools = cfg.mountPoolsAtBoot;
      };

      initrd.postDeviceCommands = mkIf cfg.impermanenceRollback mkAfter ''
        zfs rollback -r rpool/local/root@blank
      '';

    };

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };


  };
}
