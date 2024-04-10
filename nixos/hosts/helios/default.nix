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

    #containers
    podman.enable = true;
    traefik.enable = true;
    homepage.enable = true;
    sonarr.enable = true;
    radarr.enable = true;
    lidarr.enable = true;
    readarr.enable = true;
    gatus.enable = true;
    sabnzbd.enable = true;
    qbittorrent.enable = true;
  };

  mySystem.system = {
    zfs.enable = true;
    zfs.mountPoolsAtBoot = [ "tank" ];
    zfs.impermanenceRollback = true;
  };

  boot = {

    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "mpt3sas" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    # for managing/mounting ntfs
    supportedFilesystems = [ "ntfs" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # why not ensure we can memtest workstatons easily?
      grub.memtest86.enable = true;

    };
  };

  networking.hostName = "helios"; # Define your hostname.
  networking.hostId = "fae0e831"; # for zfs, helps stop importing to wrong machine
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "rpool/local/root";
      fsType = "zfs";
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
    };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/B19B-8223";
      fsType = "vfat";
    };


  swapDevices =
    [{ device = "/dev/disk/by-uuid/1d7b6e4a-aa76-4217-af18-44378c2d93d9"; }];



}
