{ lib, boot, ... }:

with lib;
{
  boot = {

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" ];
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

  # set xserver videodrivers for amp gpu
  services.xserver.videoDrivers = [ "amdgpu" ];

  # As this is a laptop explicitly enable nmcli (likely enabled by GUI anyway)
  networking.networkmanager.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}
