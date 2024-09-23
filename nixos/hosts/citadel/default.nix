# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {


  config = {
    mySystem = {
      services.openssh.enable = true;
      security.wheelNeedsSudoPassword = false;
      services.steam.enable = true;

      services.syncthing = {
        enable = true;
        syncPath = "/home/truxnell/syncthing/";
        backup = false;
        user = "truxnell";
      };

      time.hwClockLocalTime = true; # due to windows dualboot
    };

    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" "uinput" ]; # 'uniput' for sunshine
    boot.extraModulePackages = [ ];


    # xbox controller
    hardware.xone.enable = true;


    # sunshine

    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      openFirewall = true;

    };

    security.wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };

    services.udev.extraRules = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
    '';

    networking.hostName = "citadel"; # Define your hostname.

    fileSystems."/" =
      {
        device = "/dev/disk/by-uuid/701fc943-ede7-41ed-8a53-3cc38fc68fe5";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/1D5B-36D3";
        fsType = "vfat";
      };

    swapDevices = [ ];

  };


}
