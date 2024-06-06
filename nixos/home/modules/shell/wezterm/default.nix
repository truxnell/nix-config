{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.myHome.shell.wezterm;
in
{
  options.myHome.shell.wezterm = {
    enable = mkEnableOption "wezterm";
    configPath = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    # xdg.configFile."wezterm/wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink cfg.configPath;
    programs.wezterm.package = pkgs.wezterm;
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        local wez = require('wezterm')
        return {
          -- issue relating to nvidia drivers
          -- https://github.com/wez/wezterm/issues/2011
          -- had to build out 550.67 manually to 'fix'
          enable_wayland = true,

          color_scheme   = "Dracula (Official)",
          check_for_updates = false,
          window_background_opacity = .90,
          window_padding = {
            left = '2cell',
            right = '2cell',
            top = '1cell',
            bottom = '0cell',
          },
        }
      '';
    };
  };
}
