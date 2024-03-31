{ config, pkgs, lib, nixos-hardware, ... }:

{
  mySystem.services = {

    openssh.enable = true;
  };

  networking.hostName = "dns02"; # Define your hostname.
  networking.useDHCP = lib.mkDefault true;

  swapDevices = [ ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.truxnell = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZS9J1ydflZ4iJdJgO8+vnN8nNSlEwyn9tbWU9OcysW truxnell@home"
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

}
