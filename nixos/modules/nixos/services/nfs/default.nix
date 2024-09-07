{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.nfs.nas;
in
{
  options.mySystem.nfs.nas = {
    enable = mkEnableOption "Mount NAS";
    lazy = mkOption
      {
        type = lib.types.bool;
        description = "Enable lazymount";
        default = false;
      };

  };


  config = mkIf cfg.enable
    {

      services.rpcbind.enable = true; # needed for NFS

      environment.systemPackages = with pkgs; [ nfs-utils ];

      systemd.mounts = lib.mkIf cfg.lazy [{
        type = "nfs4";
        mountConfig = {
          Options = "noatime";
        };
        what = "daedalus.${config.mySystem.internalDomain}:/tank";
        where = "/mnt/nas/tank";
      }
      {
        type = "nfs4";
        mountConfig = {
          Options = "noatime";
        };
        what = "daedalus.${config.mySystem.internalDomain}:/zfs";
        where = "/mnt/nas/zfs";
      }];

      systemd.automounts = lib.mkIf cfg.lazy [{
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/nas/tank";
      }
      {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/nas/zfs";
      }];

      fileSystems."${config.mySystem.nasFolder}" = lib.mkIf (!cfg.lazy) {
        device = "daedalus.${config.mySystem.internalDomain}:/tank";
        fsType = "nfs";
      };
      fileSystems."/mnt/nas/zfs" = lib.mkIf (!cfg.lazy) {
        device = "daedalus.${config.mySystem.internalDomain}:/zfs";
        fsType = "nfs";
      };


    };
}
