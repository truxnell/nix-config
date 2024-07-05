{ config
, lib 
, pkgs
, ...
}: {
  config = {

    # hardware-configuration.nix is missing as I've abstracted out the parts

    mySystem = {
      services.openssh.enable = true;
      security.wheelNeedsSudoPassword = false;
      # services.syncthing.enable = true;
    };

    # TODO build this in from flake host names
    networking.hostName = "rickenbacker";


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
