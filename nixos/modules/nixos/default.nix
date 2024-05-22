{ lib, config, ... }:
with lib;
{
  imports = [
    ./system
    ./programs
    ./services
    ./de
    ./editor
    ./hardware
    ./containers
    ./lib.nix
    ./security
  ];

  options.mySystem.persistentFolder = mkOption {
    type = types.str;
    description = "persistent folder for nixos mutable files";
    default = "/persist";
  };

  options.mySystem.nasFolder = mkOption {
    type = types.str;
    description = "folder where nas mounts reside";
    default = "/mnt/nas";
  };
  options.mySystem.domain = mkOption {
    type = types.str;
    description = "domain for hosted services";
    default = "";
  };
  options.mySystem.internalDomain = mkOption {
    type = types.str;
    description = "domain for local devices";
    default = "";
  };
  options.mySystem.purpose = mkOption {
    type = types.str;
    description = "System purpose";
    default = "Production";
  };



  config = {
    systemd.tmpfiles.rules = [
      "d ${config.mySystem.persistentFolder} 777 - - -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

  };
}
