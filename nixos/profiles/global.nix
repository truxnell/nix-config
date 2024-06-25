{ config, lib, pkgs, imports, modulesPath, ... }:

with lib;
{
  # NOTE
  # Some 'global' areas have defaults set in their respective modules.
  # These will be applied when the modules are loaded
  # Not the global role.
  # Not sure at this point a good way to manage globals in one place
  # without mono-repo config.

  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix") # Generated by nixos-config-generate
      ./global
    ];

  config = {

    boot.tmp.cleanOnBoot = true;

    mySystem = {

      # basics for all devices
      time.timeZone = "Australia/Melbourne";
      security.increaseWheelLoginLimits = true;
      system.packages = [ pkgs.bat ];
      domain = "trux.dev";
      internalDomain = "l.voltaicforge.com";

      shell.fish.enable = true;
      # But wont enable plugins globally, leave them for workstations
      system.resticBackup.remote.location = "s3:https://f3b4625a2d02b0e6d1dec5a44f427191.r2.cloudflarestorage.com/nixos-restic";
    };

    environment.systemPackages = with pkgs; [
      curl
      wget
      dnsutils
      tree
      powertop
      parted
      smartmontools
    ];

    networking.useDHCP = lib.mkDefault true;
    networking.domain = config.mySystem.domain;

    powerManagement.powertop.enable = true;
  };

}
