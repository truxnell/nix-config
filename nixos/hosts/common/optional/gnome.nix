{
  config,
  pkgs,
  lib,
  ...
}: {
  # Ref: https://nixos.wiki/wiki/GNOME

  # GNOME plz
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager = {
      gdm.enable = true;
      defaultSession = "gnome"; # TODO move to config overlay
      autoLogin.user = "truxnell"; # TODO move to config overlay
    };
    layout = "us"; # `localctl` will give you
  };

  # And dconf
  programs.dconf.enable = true;
  # dconf write /org/gnome/mutter/experimental-features "['scale-monitor-framebuffer']"

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
}
