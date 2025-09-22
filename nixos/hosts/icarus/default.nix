# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ lib
, pkgs
, ...
}: {
  mySystem.purpose = "TV Streaming";
  mySystem.services = {
    openssh.enable = true;
  };
  mySystem.system.motd.networkInterfaces = [ "eno1" ];
  mySystem.system = {

    zfs.mountPoolsAtBoot = [ "tank" ];
  };

  networking.hostName = "daedalus"; # Define your hostname.
  networking.hostId = "8902ae79"; # for zfs, helps stop importing to wrong machine
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "rpool/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    {
      device = "rpool/local/nix";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "rpool/safe/persist";
      fsType = "zfs";
      neededForBoot = true; # for impermanence
    };

  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];

}
