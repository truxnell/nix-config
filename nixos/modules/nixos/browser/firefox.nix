{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.browser.firefox;
in
{
  options.mySystem.browser.firefox.enable = mkEnableOption "Firefox";

  config = mkIf cfg.enable {

    programs.firefox = {
      enable = true;
    };

  };


}
