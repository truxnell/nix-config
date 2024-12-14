# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./storage.nix

  ];
  config = {


    mySystem.purpose = "Network Attached Storage";
    mySystem.system.impermanence.enable = true;
    mySystem.system.autoUpgrade.enable = true; # bold move cotton
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
      qbittorrent-lts.enable = true;
      cross-seed.enable = true;
      prowlarr.enable = true;
      autobrr.enable = true;
      plex.enable = true;
      maintainerr.enable = true;
      immich.enable = true;
      filebrowser.enable = true;
      syncthing = {
        enable = true;
        syncPath = "/zfs/syncthing/";
      };
      navidrome.enable = true;
      paperless.enable = true;
      redbot.enable=true;
    };
    mySystem.security.acme.enable = true;

    mySystem.nasFolder = "/tank";
    mySystem.system.resticBackup.local.location = "/zfs/backup/nixos/nixos";

    mySystem.system = {
      zfs.enable = true;
      zfs.mountPoolsAtBoot = [ "zfs" ];
    };

    mySystem.services.nfs.enable = true;
    mySystem.system.motd.networkInterfaces = [ "eno2" ];

  # TODO abstract out?

  # Intel qsv
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };



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
    networking.hostId = "485cafad"; # for zfs, helps stop importing to wrong machine
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

    fileSystems."/mnt/cache" =
      {
        device = "/dev/disk/by-uuid/fe725638-ca41-4ecc-9b8a-7bf0807786e1";
        fsType = "xfs";
      };

    # TODO does this live somewhere else?
    # it is very machine-specific...
    # add user with `sudo smbpasswd -a my_user`
    services.samba = {
      enable = true;
      openFirewall = true;
      settings.global = {
        workgroup = "WORKGROUP";
        "server string" = "daedalus";
        "netbios name" = "daedalus";
        security = "user";
        "hosts allow" = "10.8.10. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      settings.shares = {
        backup = {
          path = "/zfs/backup";
          "read only" = "no";
        };
        documents = {
          path = "/zfs/documents";
          "read only" = "no";
        };
        natflix = {
          path = "/tank/natflix";
          "read only" = "no";
        };
        scans = {
          path = "/zfs/documents/scans";
          "read only" = "no";
        };
        paperless = {
          path = "/zfs/documents/paperless/inbound";
          "read only" = "no";
        };
      };

    };
    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

    environment.systemPackages = with pkgs; [
      btrfs-progs

    ];



    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [ "/var/lib/samba/" ];
    };


  };
}
