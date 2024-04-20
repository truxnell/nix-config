{ lib
, config
, pkgs
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

    # setup boot
    boot = {
      supportedFilesystems = [
        "zfs"
      ];
      zfs = {
        forceImportRoot = false; # if stuck on boot, modify grub options , force importing isnt secure
        extraPools = cfg.mountPoolsAtBoot;
      };


    };

    services.zfs = {
      autoScrub.enable = true;
      # Defaults to weekly and is a bit too regular for my NAS
      autoScrub.interval = "monthly";
      trim.enable = true;
    };

    # Pushover notifications
    environment.systemPackages = with pkgs; [
      busybox
    ];

    services.zfs.zed.settings = {
      ZED_PUSHOVER_TOKEN = "$(${pkgs.busybox}/bin/cat ${config.sops.secrets.pushover-api-key.path})";
      ZED_PUSHOVER_USER = "$(${pkgs.busybox}/bin/cat ${config.sops.secrets.pushover-user-key.path})";
    };

  };
}
