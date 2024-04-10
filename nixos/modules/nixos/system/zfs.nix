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
    enable = lib.mkEnableOption "zfs";
    mountPoolsAtBoot = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    impermanenceRollback = lib.mkEnableOption "Rollback root on boot for impermance";

  };

  config = lib.mkIf cfg.enable {
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        forceImportRoot = false;
        extraPools = cfg.mountPoolsAtBoot;
      };

      initrd.postDeviceCommands = lib.mkIf cfg.impermanenceRollback (lib.mkAfter ''
        zfs rollback -r rpool/local/root@blank
      '');

    };

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };


  };
}
