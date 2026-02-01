# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  lib,
  pkgs,
  ...
}:
{
  mySystem.purpose = "Homelab";
  # mySystem.system.impermanence.enable = true;
  mySystem.system.autoUpgrade = {
    enable = true;
    dates = "Wed 06:00";
  }; # bold move cotton
  mySystem.services = {
    # Infrastructure
    # System
    openssh.enable = true;
    podman.enable = true;
    # Databases
    postgresql.enable = true;
    mariadb.enable = true;
    # Web server
    nginx.enable = true;

    # Monitoring
    # Metrics
    victoriametrics.enable = true;
    grafana.enable = true;
    unpoller.enable = true;
    # Monitoring tools
    gatus.enable = true;
    hs110-exporter.enable = true;
    promtail.enable = true;

    # Media
    # Plex monitoring
    tautulli.enable = true;

    # Automation/IoT
    # MQTT
    mosquitto.enable = true;
    zigbee2mqtt.enable = true;
    rapt2mqtt.enable = true;
    # Automation
    # n8n.enable = true;  
    node-red.enable = true;
    home-assistant.enable = true;

    # Search
    searxng.enable = true;
    whoogle.enable = true;
    redlib.enable = true;

    # Productivity
    # RSS
    miniflux.enable = true;
    rss-bridge.enable = true;
    # Organization
    radicale.enable = true;
    changedetection.enable = true;
    linkding.enable = true;
    # Password management
    vaultwarden.enable = true;
    # Communication
    thelounge.enable = true;
    # Tools
    rxresume.enable = true;

    # Development
    code-server.enable = true;

    # Gaming
    # factorio.freight-forwarding.enable = true; # the factory must grow
    factorio.space-age.enable = true; # the factory must launch into space
    satisfactory.enable = true; # the factory must be satisfactory
    minecraft-bedrock.CordiWorld.enable = true;
    minecraft-bedrock.survival.enable = true;

    # Networking
    technitium-dns-server.enable = true;

    # Misc
    firefly-iii.enable = true;
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

    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
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

  fileSystems."/" = {
    device = "rpool/local/root";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/nix" = {
    device = "rpool/local/nix";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/persist" = {
    device = "rpool/safe/persist";
    fsType = "zfs";
    options = [ "zfsutil" ];
    neededForBoot = true; # for impermanence
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/76FA-78DF";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

}
