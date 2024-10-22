{ config, lib, pkgs, imports, boot, self, inputs, ... }:
# Role for workstations
# Covers desktops/laptops, expected to have a GUI and do worloads
# Will have home-manager installs

with config;
{


  mySystem = {

    de.kde.enable = true;
    editor.vscodium.enable = true;

    # Lets see if fish everywhere is OK on the pi's
    # TODO decide if i drop to bash on pis?
    shell.fish.enable = true;

    nfs.nas = {
      enable = true;
      lazy = true;
    };
    system.resticBackup.local.enable = false;
    system.resticBackup.remote.enable = false;

  };

  boot = {

    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Enabled for raspi4 compilation
    plymouth.enable = true; # hide console with splash screen

  };

  nix.settings = {
    # TODO factor out into mySystem
    # Avoid disk full issues
    max-free = lib.mkDefault (1000 * 1000 * 1000);
    min-free = lib.mkDefault (128 * 1000 * 1000);
  };

  # set xserver videodrivers if used
  services.xserver.enable = true;

  services = {
    fwupd.enable = config.boot.loader.systemd-boot.enable; # fwupd does not work in BIOS mode
    thermald.enable = true;
    smartd.enable = true;

    # required for yubikey
    udev.packages = [ pkgs.yubikey-personalization pkgs.android-udev-rules ];
    pcscd.enable = true;
  };

  users.users.truxnell.extraGroups = [ "adbusers" ];


  hardware = {
    enableAllFirmware = true;
    sensor.hddtemp = {
      enable = true;
      drives = [ "/dev/disk/by-id/*" ];
    };
  };

  environment.systemPackages = with pkgs; [

    # Sensors etc
    lm_sensors
    cpufrequtils
    cpupower-gui



  ];

  # split out
  programs.gamemode = {
      enable = true;
      settings = {
        general = {
          softrealtime = "auto";
          renice = 15;
        };
      };
    };


  i18n = {
    defaultLocale = lib.mkDefault "en_AU.UTF-8";
  };

  programs.mtr.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
}
