{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.sonarr;
in
{
  options.mySystem.services.sonarr.enable = mkEnableOption "Sonarr";

  config = mkIf cfg.enable {

    services.sonarr = {
      enable = true;
      dataDir = "${config.mySystem.persistentFolder}/nixos/sonarr/";
    };

  };
}
