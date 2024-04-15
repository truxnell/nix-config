{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.powerdns;
in
{
  options.mySystem.services.powerdns.enable = mkEnableOption "powerdns";

  config = mkIf cfg.enable {

    services.powerdns = {
      enable = true;

    };

  };
}
