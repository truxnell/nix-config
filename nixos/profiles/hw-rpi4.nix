{ config, lib, pkgs, imports, boot, ... }:

with lib;
{
  boot = {

    initrd.availableKernelModules = [ "xhci_pci" "usb_storage" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];

    loader = {
      # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
      grub.enable = false;
      # Enables the generation of /boot/extlinux/extlinux.conf
      generic-extlinux-compatible.enable = true;
    };
  };

  console.enable = false;
  mySystem.system.packages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];


  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

}
