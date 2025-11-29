{
  lib,
  ...
}:
{
  config = {
    networking.hostName = "xerxes";
    networking.useDHCP = lib.mkDefault true;
    system.stateVersion = lib.mkDefault "23.11";


 boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/vda" ];
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/3829960b-43f1-4d64-9bd9-2286e8c0345f";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/7e2ffce0-4f21-45a8-93b2-9ea83377f9ec"; }
    ];


  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
  
}

