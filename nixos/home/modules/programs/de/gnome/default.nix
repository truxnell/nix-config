# Adjusted manually from generated output of dconf2nix
# https://github.com/gvolpe/dconf2nix
{ lib
, pkgs
, osConfig
, ...
}:
with lib.hm.gvariant; {

  config = lib.mkIf osConfig.mySystem.de.gnome.enable {
    # add user packages
    home.packages = with pkgs;  [
      dconf2nix
    ];

    # worked out from dconf2nix
    # dconf dump / | dconf2nix > dconf.nix
    # can also dconf watch
    dconf.settings = {
      "org/gnome/desktop/calendar" = {
        show-weekdate = true;
      };

      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        search-filter-time-type = "last_modified";
        search-view = "list-view";
      };

      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-last-coordinates = mkTuple [ 48.135501 16.3855 ];
        night-light-temperature = mkUint32 3700;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "suspend";
        sleep-inactive-ac-timeout = 3600;
        sleep-inactive-ac-type = "nothing";
      };

      "org/gnome/mutter" = {
        edge-tiling = true;
        workspaces-only-on-primary = false;
      };

      "org/gnome/desktop/wm/preferences" = {
        workspace-names = [ "sys" "talk" "web" "edit" "run" ];
      };

      "org/gnome/shell" = {
        disabled-extensions = [ "apps-menu@gnome-shell-extensions.gcampax.github.com" "light-style@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "window-list@gnome-shell-extensions.gcampax.github.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com" ];
        enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" "caffeine@patapon.info" "dash-to-dock@micxgx.gmail.com" "gsconnect@andyholmes.github.io" "sp-tray@sp-tray.esenliyim.github.com" "tilingshell@ferrarodomenico.com" ];
        favorite-apps = [ "org.gnome.Nautilus.desktop" "firefox.desktop" "org.wezfurlong.wezterm.desktop" "PrusaGcodeviewer.desktop" "spotify.desktop" "org.gnome.Console.desktop" "codium.desktop" "discord.desktop" ];
      };

      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
      };

      "org/gnome/shell/weather" = {
        automatic-location = true;
        locations = "[<(uint32 2, <('Melbourne Airport', 'YMML', false, [(-0.65740735740229495, 2.5278185274873568)], @a(dd) [])>)>]";
      };

      "system/locale" = {
        region = "en_GB.UTF-8";
      };
    };
  };
}
