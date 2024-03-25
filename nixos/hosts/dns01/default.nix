# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs 
, ...
}: {
  imports = [
    ../common/optional/fish.nix
    ../common/optional/monitoring.nix
    ../common/optional/reboot-required.nix

    ../common/optional/dnscrypt-proxy2.nix
    ../common/optional/cloudflare-dyndns.nix
    ../common/optional/maddy.nix
  ];

  networking.hostName = "dns01"; # Define your hostname.
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };

  swapDevices = [ ];



}
