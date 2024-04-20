{ config, lib, pkgs, imports, boot, self, ... }:
# Role for headless servers
# covers raspi's, sbc, NUC etc, anything
# that is headless and minimal for running services

with lib;
{


  config = {


    # Enable monitoring for remote scraiping
    mySystem.services.promMonitoring.enable = true;
    mySystem.services.rebootRequiredCheck.enable = true;
    mySystem.security.wheelNeedsSudoPassword = false;
    mySystem.services.cockpit.enable = true;
    mySystem.system.motd.enable = true;
    mySystem.services.gatus.monitors = [{
      name = config.networking.hostName;
      group = "servers";
      url = "icmp://${config.networking.hostName}.${config.mySystem.internalDomain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" ];
    }];

    nix.settings = {
      # TODO factor out into mySystem
      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);
    };

    services.logrotate.enable = mkDefault true;

    environment.noXlibs = mkDefault true;
    documentation = {
      enable = mkDefault false;
      doc.enable = mkDefault false;
      info.enable = mkDefault false;
      man.enable = mkDefault false;
      nixos.enable = mkDefault false;
    };
    programs.command-not-found.enable = mkDefault false;

    sound.enable = false;
    hardware.pulseaudio.enable = false;


    services.udisks2.enable = mkDefault false;
    # xdg = {
    #   autostart.enable = mkDefault false;
    #   icons.enable = mkDefault false;
    #   mime.enable = mkDefault true;
    #   sounds.enable = mkDefault false;
    # };
  };

}
