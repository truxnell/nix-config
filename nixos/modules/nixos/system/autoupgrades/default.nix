{
  lib,
  config,
  ...
}:
let
  cfg = config.mySystem.system.autoUpgrade;
in
with lib;
{
  options.mySystem.system.autoUpgrade = {
    enable = mkEnableOption "system autoUpgrade";
    dates = lib.mkOption {
      type = lib.types.str;
      default = "Sun 06:00";
    };

  };
  config.system.autoUpgrade = mkIf cfg.enable {
    enable = true;
    flake = "github:truxnell/nix-config";
    flags = [
      "-L" # print build logs
    ];
    inherit (cfg) dates;
  };

}
