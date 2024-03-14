{ config, pkgs, lib, ... }:

{
    # Ref: https://nixos.wiki/wiki/GNOME

    # Enable GNOME with this 3 wierd tricks
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # And dconf
    programs.dconf.enable = true;

    # Exclude default GNOME packages that dont interest me.
    environment.gnome.excludePackages = (with pkgs; [
        gnome-photos
        gnome-tour
    ]) ++ (with pkgs.gnome; [
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