{ config, lib, pkgs, imports, boot, ... }:
# Role for workstations
# Covers desktops/laptops, expected to have a GUI and do worloads
# Will have home-manager installs

with lib;
{

  config.mySystem.shell.fish.plugins = true;
  config.boot = {

    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Enabled for raspi4 compilation
    plymouth.enable = true; # hide console with splash screen
  };

  config.nix.settings = {
    # TODO factor out into mySystem
    # Avoid disk full issues
    max-free = lib.mkDefault (1000 * 1000 * 1000);
    min-free = lib.mkDefault (128 * 1000 * 1000);
  };

  # set xserver videodrivers if used
  config.services.xserver.enable = true;

  # Laptop so ill likely use wireles
  # very likely to be set by GUI packages but lets
  # be declarative.


}
