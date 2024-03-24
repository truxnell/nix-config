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
    };
  };

  # set xserver videodrivers if used
  services.xserver.videoDrivers = [ "amdgpu" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}
