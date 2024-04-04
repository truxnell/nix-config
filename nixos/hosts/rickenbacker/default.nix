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
    };
    mySystem.services.traefik.enable = true;

    # TODO build this in from flake host names
    networking.hostName = "rickenbacker";
    networking.extraHosts =
      ''
        10.8.20.33 traefik.trux.dev
      '';


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
