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


    };

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };


  };
}
