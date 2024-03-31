{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.mySystem.xx.yy;
in
{
  options.mySystem.xx.yy.enable = mkEnableOption "<INSERT DESCRIPTION>";

  config = mkIf cfg.enable {

    # CONFIG HERE

  };


}
