{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.programs.steam;
in
{
  options.mySystem.programs.steam.enable = mkEnableOption "steam";

  config = mkIf cfg.enable {

    programs.steam.enable = true;

  };


}
