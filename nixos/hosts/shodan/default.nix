# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  mySystem.purpose = "Homelab";
  mySystem.system.impermanence.enable = true;
  mySystem.system.autoUpgrade.enable=true; # bold move cotton
  mySystem.services = {
    openssh.enable = true;
    podman.enable = true;
    # databases
    postgresql.enable = true;
    mariadb.enable = true;

    # frigate.enable = true;

    nginx.enable = true;

    gatus.enable = true;
    homepage.enable = true;
    # backrest.enable = true;

    overseerr.enable = true;
    tautulli.enable = true;

    factorio.freight-forwarding.enable = true; # the factory must grow

    searxng.enable = true;
    whoogle.enable = true;
    redlib.enable = true;

    mosquitto.enable = true;
    zigbee2mqtt.enable = true;
    node-red.enable = true;
    home-assistant.enable = true;
    code-server.enable = true; # Why is this bringing in gtk and wayland?

    radicale.enable = true;
    miniflux.enable = true;
    calibre-web.enable = true;
    rss-bridge.enable = true;
    # paperless.enable = true;
    rxresume.enable = true;
    invidious.enable = true;
    thelounge.enable = true;
    changedetection.enable = true;
    linkding.enable = true;

    # monitoring
    victoriametrics.enable = true;
    grafana.enable = true;
    nextdns-exporter.enable = true;
    unpoller.enable = true;

    hs110-exporter.enable = true;

  };

  mySystem.containers = {
    calibre.enable = true;
    ecowitt2mqtt.enable = true;
    maloja.enable = true;
    multi-scrobbler.enable = true;

  };


  mySystem.security.acme.enable = true;

  mySystem.nfs.nas.enable = true;
  mySystem.persistentFolder = "/persist";
  mySystem.system.motd.networkInterfaces = [ "enp1s0" ];

  mySystem.nasFolder = "/mnt/nas";
  mySystem.system.resticBackup.local.location = "/mnt/nas/backup/nixos/nixos";


  boot = {

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # for managing/mounting ntfs
    supportedFilesystems = [ "ntfs" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # why not ensure we can memtest workstatons easily?
      # TODO check whether this is actually working, cant see it in grub?
      grub.memtest86.enable = true;

    };
  };

  networking.hostName = "shodan"; # Define your hostname.
  networking.hostId = "0a90730f";
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "rpool/local/root";
      fsType = "zfs";
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

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/76FA-78DF";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

}
