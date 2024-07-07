# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  mySystem.purpose = "Media Streaming";
  mySystem.system.impermanence.enable = true;
  mySystem.system.autoUpgrade.enable = true; # bold move cotton
  mySystem.services = {
    openssh.enable = true;

  };

  mySystem.nfs.nas.enable = true;
  mySystem.persistentFolder = "/persist";
  mySystem.system.motd.networkInterfaces = [ "enp1s0" ];

  mySystem.nasFolder = "/mnt/nas";
  mySystem.system.resticBackup.local.location = "/mnt/nas/backup/nixos/nixos";

  # TODO fix this bit of a hack
  users.users.kah = {
    uid = 568;
    group = "kah";
  };
  users.groups.kah = { };

  users.users.moonlight = {
    uid = 1002;
    group = "moonlight";
    isNormalUser = true;
  };
  users.groups.moonlight = { };

  services.getty.autologinUser = "moonlight";
  environment.persistence."${config.mySystem.system.impermanence.persistPath}" = {
    directories = [{ directory = "/home/moonlight/.config/Moonlight Game Streaming Project"; user = "moonlight"; group = "moonlight"; mode = "750"; }];
  };

  # TODO abstract out?

  # Intel qsv
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };

  # set xserver videodrivers if used
  services.xserver = {
    enable = true;
    autorun = true;
    displayManager.startx.enable = true;
  };

  programs.fish.promptInit = ''
    if test (tty) = "/dev/tty1"
        startx moonlight
    end
  '';

  boot = {

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # for managing/mounting ntfs
    supportedFilesystems = [ "ntfs" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # why not ensure we can memtest workstatons easily?
      # TODO check whether this is actually working, cant see it in grub?
      grub.memtest86.enable = true;

    };
  };

  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];


  networking.hostName = "playsatan"; # Define your hostname.
  networking.hostId = "b8cc9645";
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "rpool/local/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/72A3-FA67";
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

  swapDevices = [ ];

}
