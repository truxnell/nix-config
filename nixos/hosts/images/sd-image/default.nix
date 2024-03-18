{ config, pkgs, lib, ... }:

{
  # imports = [
  #   <nixos-hardware/raspberry-pi/4>
  # ];

  nixpkgs = {

    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  boot = {
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
    ];
    loader = {
      grub.enable = false;
      raspberryPi = {
        version = 4;
      };
    };
  };

  # # https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4
  # hardware = {
  #   raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  #   deviceTree = {
  #     enable = true;
  #     filter = "*rpi-4-*.dtb";
  #   };
  # };

  console.enable = false;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  networking = {
    hostName = "nixos";
    wireless.enable = false;
    networkmanager.enable = false;
  };
  services.openssh.enable = true;

  # Free up to 1GiB whenever there is less than 100MiB left.
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';
  nixpkgs.hostPlatform = "aarch64-linux";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1.... username@tld"
  ];
  system.stateVersion = "23.11";

}
