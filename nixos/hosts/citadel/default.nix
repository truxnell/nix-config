# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, ...
}: {


  config = {
    mySystem = {
      services.openssh.enable = true;
      security.wheelNeedsSudoPassword = false;
      system.autoUpgrade.enable = true; # bold move cotton
      time.hwClockLocalTime = true; # due to windows dualboot
      services.syncthing = {
        enable = true;
        syncPath = "/home/truxnell/syncthing/";
        dataDir = "/home/truxnell/syncthing/";
        backup = false;
        user = "truxnell";
      };
      services.steam = {
        enable = true;
        hdr = true;
      };
    };




    hardware.bluetooth.enable = true;


    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" "uinput" ]; # 'uniput' for sunshine
    boot.extraModulePackages = [ ];
    boot.kernelParams = [
    ];

    networking.hostId = "f8122c14"; # for zfs, helps stop importing to wrong machine
    # mySystem.system.impermanence.enable = true;


    # xbox controller
    hardware.xone.enable = true;


    # sunshine


    networking.hostName = "citadel"; # Define your hostname.

    fileSystems."/" =
      {
        device = "rpool/local/root";
        fsType = "zfs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/1D5B-36D3";
        fsType = "vfat";
        options = [ "fmask=0022" "dmask=0022" ];
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

    fileSystems."/home" =
      {
        device = "rpool/safe/home";
        fsType = "zfs";
      };
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


    swapDevices = [ ];

  };


}
