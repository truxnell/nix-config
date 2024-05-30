{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.mySystem.de.gnome;
in
{
  options.mySystem.de.gnome.enable = mkEnableOption "GNOME";
  options.mySystem.de.gnome.systrayicons = mkEnableOption "Enable systray icons" // { default = true; };
  options.mySystem.de.gnome.gsconnect = mkEnableOption "Enable gsconnect (KDEConnect for GNOME)" // { default = true; };


  config = mkIf cfg.enable {

    # Ref: https://nixos.wiki/wiki/GNOME

    # GNOME plz
    services = {
      xserver = {
        enable = true;
        displayManager =
          {
            gdm.enable = true;
            defaultSession = "gnome"; # TODO move to config overlay

            autoLogin.enable = true;
            autoLogin.user = "truxnell"; # TODO move to config overlay
          };
        desktopManager = {
          # GNOME
          gnome.enable = true;
        };

        layout = "us"; # `localctl` will give you
      };
      udev.packages = optionals cfg.systrayicons [ pkgs.gnome.gnome-settings-daemon ]; # support appindicator


    };

    # systyray icons


    # extra pkgs and extensions
    environment = {
      systemPackages = with pkgs; [
        wl-clipboard # ls ~/Downloads | wl-copy or wl-paste > clipboard.txt
        playerctl # gsconnect play/pause command
        pamixer # gcsconnect volume control
        gnome.gnome-tweaks
        gnome.dconf-editor

        # This installs the extension packages, but
        # dont forget to enable them per-user in dconf settings -> "org/gnome/shell"
        gnomeExtensions.caffeine
        gnomeExtensions.spotify-tray
        gnomeExtensions.dash-to-dock

      ]
      ++ optionals cfg.systrayicons [ pkgs.gnomeExtensions.appindicator ];
    };

    # enable gsconnect
    # this method also opens the firewall ports required when enable = true
    programs.kdeconnect = mkIf
      cfg.gsconnect
      {
        enable = true;
        package = pkgs.gnomeExtensions.gsconnect;
      };

    # GNOME connection to browsers - requires flag on browser as well
    services.gnome.gnome-browser-connector.enable = lib.any
      (user: user.programs.firefox.enable)
      (lib.attrValues config.home-manager.users);

    # TODO remove this when possible
    # workaround for GNOME autologin
    # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # TODO tidy this
    # port forward for GNOME when using RDP***REMOVED***

    # for RDP TODO make this a flag if RDP is enabled per host
    networking.firewall.allowedTCPPorts = [
      3389
    ];

    # And dconf
    programs.dconf.enable = true;

    # https://github.com/NixOS/nixpkgs/issues/114514
    # dconf write /org/gnome/mutter/experimental-features "['scale-monitor-framebuffer']" TODO hack for GNOME 45


    # Exclude default GNOME packages that dont interest me.
    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese # webcam tool
        gnome-music
        gnome-terminal
        epiphany # web browser
        geary # email reader
        evince # document viewer
        gnome-characters
        totem # video player
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
      ]);
  };


}
