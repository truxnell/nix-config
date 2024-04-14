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
  options.mySystem.system.resticBackup.local = {
    enable = mkEnableOption "Local backups" // { default = true; };
    location = mkOption
      {
        type = types.str;
        description = "Location for local backups";
        default = "";
      };
  };
  options.mySystem.resticBackup.remote = {
    enable = mkEnableOption "remote backups";
    location = mkOption
      {
        type = types.str;
        description = "Location for remote backups";
        default = "";
      };
  };

  config = mkIf (cfg.local.enable or cfg.remote.enable) {
    sops.secrets."services/restic/password" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "kah";
      group = "kah";
    };

  };
}
