{ config
, ...
}: {
  config = {

    # hardware-configuration.nix is missing as I've abstracted out the parts

    mySystem = {
      services.openssh.enable = true;
      security.wheelNeedsSudoPassword = false;
      system.autoUpgrade.enable = true; # bold move cotton
      services.syncthing = {
        enable = true;
        syncPath = "/home/truxnell/syncthing/";
        backup = false;
        user = "truxnell";
      };
      services.steam = {
        enable = true;
        hdr = true;
      };
    };

    # TODO build this in from flake host names
    networking.hostName = "rickenbacker";

    hardware.bluetooth.enable = true;



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
