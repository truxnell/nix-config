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

  # Temporary make .config/wezterm/wezterm.lua link to the local copy
  config = mkIf cfg.enable {
    # xdg.configFile."wezterm/wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink cfg.configPath;
    programs.wezterm = {
      enable = true;
    };
  };
}
