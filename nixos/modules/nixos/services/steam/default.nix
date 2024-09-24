{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "steam";
  category = "services";
  description = "steam with gamescope";
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      hdr = mkEnableOption "hdr support";
    };

  config = mkIf cfg.enable {

    # gamescope for HDR
    programs.steam = {
      enable = true;
      gamescopeSession = mkIf cfg.hdr {
        enable = true; # Gamescope session is better for AAA gaming.
        env = {
          SCREEN_WIDTH = "3840";
          SCREEN_HEIGHT = "2160";
        };
        args = [
          "--hdr-enabled"
          "--hdr-itm-enable"
        ];
      };
    };
    programs.gamescope = mkIf cfg.hdr {
      enable = true;
      capSysNice = false; # capSysNice freezes gamescopeSession for me.
      args = [ ];
      env = lib.mkForce {
        WLR_RENDERER = "vulkan";
        DXVK_HDR = "1";
        ENABLE_GAMESCOPE_WSI = "1";
        WINE_FULLSCREEN_FSR = "1";
      };
    };

    environment.variables.WINE_FULLSCREEN_FSR = mkIf cfg.hdr "1";



  };
}
