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
  options.mySystem.nfs.nas.enable = mkEnableOption "Mount NAS";

  config = mkIf cfg.enable
    {

      services.rpcbind.enable = true; # needed for NFS

      environment.systemPackages = with pkgs; [ nfs-utils ];

      systemd.mounts = [{
        type = "nfs";
        mountConfig = {
          Options = "noatime";
        };
        what = "daedalus.${config.mySystem.internalDomain}:/tank";
        where = "/mnt/nas";
      }];

      systemd.automounts = [{
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
        where = "/mnt/nas";
      }];

    };
}
