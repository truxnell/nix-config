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
    dnscrypt-proxy.enable = true;
    cfDdns.enable = true;
  };

  networking.hostName = "dns02"; # Define your hostname.
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

  swapDevices = [ ];



}
