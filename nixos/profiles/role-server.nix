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

    nix.settings = {
      # TODO factor out into mySystem
      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);
    };
  };



}
