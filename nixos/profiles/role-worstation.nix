{ config, lib, pkgs, imports, boot, self, ... }:
# Role for workstations
# Covers desktops/laptops, expected to have a GUI and do worloads
# Will have home-manager installs

with config;
{


  mySystem = {

    de.gnome.enable = true;
    editor.vscodium.enable = true;

    # Lets see if fish everywhere is OK on the pi's
    # TODO decide if i drop to bash on pis?
    shell.fish.enable = true;

    nfs.nas.enable = true;
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
    udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;
  };

  hardware = {
    enableAllFirmware = true;
    sensor.hddtemp = {
      enable = true;
      drives = [ "/dev/disk/by-id/*" ];
    };
  };



  environment.systemPackages = with pkgs; [
    jq
    yq
    btop
    vim
    unstable.deploy-rs
    git
    dnsutils
    nix

    # Sensors etc
    lm_sensors
    cpufrequtils
    cpupower-gui

    # TODO Move
    nil
    nixpkgs-fmt
    statix
    nvd
    gh

    bind # for dns utils like named-checkconf
  ];

  i18n = {
    defaultLocale = lib.mkDefault "en_AU.UTF-8";
  };


  programs.direnv = {
    # TODO move to home-manager
    enable = true;
    nix-direnv.enable = true;
  };
  programs.mtr.enable = true;
}
