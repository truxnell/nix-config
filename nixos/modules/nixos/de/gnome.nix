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

  config = mkIf cfg.enable {

    # Ref: https://nixos.wiki/wiki/GNOME

    # GNOME plz
    services.xserver = {
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
        gedit # text editor
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
