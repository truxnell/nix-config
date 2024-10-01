
{ lib
, pkgs
, osConfig
, config
, ...
}:
let
  app = "emulation";
  cfg = config.myHome.gaming.${app};
in
with lib; {
  options.myHome.gaming.${app} =
    {
      enable = mkEnableOption "${app}";
    };

  config = mkIf cfg.enable {

    home.packages = with pkgs; [
      steam-rom-manager
      nsz
      ryujinx
    ];

  };

}