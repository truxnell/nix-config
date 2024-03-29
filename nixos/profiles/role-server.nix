{ config, lib, pkgs, imports, boot, ... }:
# Role for headless servers
# covers raspi's, sbc, NUC etc, anything
# that is headless and minimal for running services

with lib;
{
  config = {

    # Enable monitoring for remote scraiping
    mySystem.services.promMonitoring.enable = true;
    mySystem.services.rebootRequiredCheck.enable = true;

    services.logrotate.enable = mkDefault true;

    nix.settings = {
      # TODO factor out into mySystem
      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);
    };


    # Minimise build size
    # ref: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/minimal.nix;
    environment.noXlibs = mkDefault true;

    documentation.enable = mkDefault false;

    documentation.doc.enable = mkDefault false;

    documentation.info.enable = mkDefault false;

    documentation.man.enable = mkDefault false;

    documentation.nixos.enable = mkDefault false;

    programs.command-not-found.enable = mkDefault false;

    services.udisks2.enable = mkDefault false;

    xdg.autostart.enable = mkDefault false;
    xdg.icons.enable = mkDefault false;
    xdg.mime.enable = mkDefault false;
    xdg.sounds.enable = mkDefault false;
  };

}
