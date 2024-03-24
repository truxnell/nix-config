{ config
, lib
, pkgs
, ...
}: {

  # hardware-configuration.nix is missing as I've abstracted out the parts
  # into various areas like my global/hardware profiles, etc.
  imports = [

    # Common imports
    ../common/nixos/users/truxnell
    ../common/optional/fish.nix
    ../common/optional/gnome.nix
    ../common/optional/editors/vscode
    ../common/optional/firefox.nix

  ];
  config.mySystem = {
    services.openssh.enable = true;
    security.wheelNeedsSudoPassword = false;
  };

  # TODO build this in from flake host names
  config.networking.hostName = "rickenbacker";

  config = {

    fileSystems."/" =
      {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-uuid/44D0-91EC";
        fsType = "vfat";
      };

    swapDevices = [ ];
  };
}
