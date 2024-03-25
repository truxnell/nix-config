# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [

    # Common imports
    ../common/optional/gnome.nix
    ../common/optional/editors/vscode
    ../common/optional/firefox.nix

  ];
  config = {
    mySystem = {
      services.openssh.enable = true;
      security.wheelNeedsSudoPassword = false;
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
