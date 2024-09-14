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

      time.hwClockLocalTime = true; # due to windows dualboot
    };

    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];

    # xbox controller
    hardware.xone.enable = true;

    # gamescope for HDR
    programs.steam = {
      enable = true;
      gamescopeSession = {
        enable = true; # Gamescope session is better for AAA gaming.
        env = {
          SCREEN_WIDTH = "3840";
          SCREEN_HEIGHT = "2160";
        };
        args = [
          "--hdr-enabled"
          "--hdr-itm-enable"
        ];
      };
    };
    programs.gamescope = {
      enable = true;
      capSysNice = true; # capSysNice freezes gamescopeSession for me.
      args = [ ];
      env = lib.mkForce {
        WLR_RENDERER = "vulkan";
        DXVK_HDR = "1";
        ENABLE_GAMESCOPE_WSI = "1";
        WINE_FULLSCREEN_FSR = "1";
      };
    };

    environment.variables.WINE_FULLSCREEN_FSR = "1";

    # sunshine

    services.sunshine =
      {
        enable = true;
        capSysAdmin = true;
        openFirewall = true;

      };

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
