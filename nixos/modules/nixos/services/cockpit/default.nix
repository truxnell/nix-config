{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.mySystem.services.cockpit;
in
{
  options.mySystem.services.cockpit.enable = mkEnableOption "Cockpit";

  config = mkIf cfg.enable {
    services.cockpit.enable = true;
    services.cockpit.openFirewall = true;

  };


}
