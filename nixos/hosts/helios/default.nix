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

  mySystem.services.nfs.enable = true;

  boot = {

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "mpt3sas" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

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
  networking.hostId = "847817ba"; # for zfs, helps stop importing to wrong machine
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "rpool/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/4D87-0642";
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
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/4939bb1a-221c-455a-9011-a633f81490da"; }];



}
