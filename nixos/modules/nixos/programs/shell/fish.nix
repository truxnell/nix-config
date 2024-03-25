{ lib
, config
, self
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.shell.fish;
in
{
  options.mySystem.shell.fish =
    {
      enable = mkEnableOption "Fish";
      enablePlugins = mkOption
        {
          type = lib.types.bool;
          description = "If we want to add fish plugins";
          default = true;

        };

    };

  # Install fish systemwide
  config.programs.fish = mkIf cfg.enable {
    enable = true;
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

}
