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
      "org/gnome/mutter" = {
        edge-tiling = true;
        workspaces-only-on-primary = false;
      };
      "org/gnome/desktop/wm/preferences" = {
        workspace-names = [ "sys" "talk" "web" "edit" "run" ];
      };
      "org/gnome/shell" = {
        disabled-extensions = [ "apps-menu@gnome-shell-extensions.gcampax.github.com" "light-style@gnome-shell-extensions.gcampax.github.com" "places-menu@gnome-shell-extensions.gcampax.github.com" "drive-menu@gnome-shell-extensions.gcampax.github.com" "window-list@gnome-shell-extensions.gcampax.github.com" "workspace-indicator@gnome-shell-extensions.gcampax.github.com" ];
        enabled-extensions = [ "appindicatorsupport@rgcjonas.gmail.com" "caffeine@patapon.info" "dash-to-dock@micxgx.gmail.com" "gsconnect@andyholmes.github.io" "Vitals@CoreCoding.com" "sp-tray@sp-tray.esenliyim.github.com" ];
        favorite-apps = [ "org.gnome.Nautilus.desktop" "firefox.desktop" "org.wezfurlong.wezterm.desktop" "PrusaGcodeviewer.desktop" "spotify.desktop" "org.gnome.Console.desktop" "codium.desktop" "discord.desktop"];
      };
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
      };
      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "small";
      };

    };
  };
}
