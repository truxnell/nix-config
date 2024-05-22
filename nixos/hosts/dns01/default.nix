# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [


  ];

  mySystem.services = {

    openssh.enable = true;
    cfDdns.enable = true;
    powerdns = {
      enable = true;
      admin-ui = false;
    };
    adguardhome.enable = true;
  };

  # no mutable state I care about
  mySystem.system.resticBackup =
    {
      local.enable = false;
      remote.enable = false;
    };
  mySystem.system.autoUpgrade = {
    enable = true;
  };


  networking.hostName = "dns01"; # Define your hostname.
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

  swapDevices = [ ];



}
