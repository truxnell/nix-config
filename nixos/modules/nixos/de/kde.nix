{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.de.kde;
in
{
  options.mySystem.de.kde.enable = mkEnableOption "kde";
  options.mySystem.de.kde.systrayicons = mkEnableOption "Enable systray icons" // { default = true; };
  options.mySystem.de.kde.gsconnect = mkEnableOption "Enable gsconnect (KDEConnect for GNOME)" // { default = true; };


  config = mkIf cfg.enable {

    # Ref: https://nixos.wiki/wiki/GNOME

    # GNOME plz
    services = {
      xserver.enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;

      # printing
      printing.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

    };

    programs.kdeconnect.enable = true;

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

  };


}
