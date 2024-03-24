{ config, lib, pkgs, imports, boot, ... }:

with lib;
{
  boot = {

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    initrd.kernelModules = [ "amdgpu" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # why not ensure we can memtest workstatons easily?
      grub.memtest86.enable = true;

    };
  };

  # set xserver videodrivers for amp gpu
  services.xserver.videoDrivers = [ "amdgpu" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}
