# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [


  ];
  config = {
    mySystem.purpose = "Network Attached Storage";
    mySystem.system.impermanence.enable = true;
    mySystem.services = {
      openssh.enable = true;
      minio.enable = true;
      podman.enable = true;
      nginx.enable = true;
      sonarr.enable = true;
      radarr.enable = true;
      recyclarr.enable = true;
      lidarr.enable = true;
      readarr.enable = true;
      sabnzbd.enable = true;
      qbittorrent.enable = true;
      prowlarr.enable = true;


    };
    mySystem.security.acme.enable = true;

    mySystem.nasFolder = "/tank";
    mySystem.system.resticBackup.local.location = "/tank/backup/nixos/nixos";

    mySystem.system = {
      zfs.enable = true;
      zfs.mountPoolsAtBoot = [ "tank" ];
    };

    mySystem.services.nfs.enable = true;
    mySystem.system.motd.networkInterfaces = [ "eno1" ];


    boot = {

      initrd.availableKernelModules = [ "xhci_pci" "ahci" "mpt3sas" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];

      # for managing/mounting ntfs
      supportedFilesystems = [ "ntfs" ];

      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # why not ensure we can memtest workstatons easily?
        grub.memtest86.enable = true;

      };
    };

    networking.hostName = "daedalus"; # Define your hostname.
    networking.hostId = "ed3980cb"; # for zfs, helps stop importing to wrong machine
    networking.useDHCP = lib.mkDefault true;

    fileSystems."/" =
      {
        device = "rpool/local/root";
        fsType = "zfs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-label/EFI";
        fsType = "vfat";
      };

    fileSystems."/nix" =
      {
        device = "rpool/local/nix";
        fsType = "zfs";
      };

    fileSystems."/persist" =
      {
        device = "rpool/safe/persist";
        fsType = "zfs";
        neededForBoot = true; # for impermanence
      };

    swapDevices =
      [{ device = "/dev/disk/by-uuid/c2f716ef-9e8c-466b-bcb0-699397cb2dc0"; }];

    # TODO does this live somewhere else?
    # it is very machine-specific...
    # add user with `sudo smbpasswd -a my_user`
    services.samba = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        workgroup = WORKGROUP
        server string = daedalus
        netbios name = daedalus
        security = user
        #use sendfile = yes
        #max protocol = smb2
        # note: localhost is the ipv6 localhost ::1
        hosts allow = 10.8.10. 127.0.0.1 localhost
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
        backup = {
          path = "/tank/backup";
          "read only" = "no";
        };
        documents = {
          path = "/tank/documents";
          "read only" = "no";
        };
        natflix = {
          path = "/tank/natflix";
          "read only" = "no";
        };
        # paperless = {
        #   path = "/tank/Apps/paperless/incoming";
        #   "read only" = "no";
        # };
      };

    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [ "/var/lib/samba/" ];
    };


  };
}
