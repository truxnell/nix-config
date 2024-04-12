{ lib, config, ... }:
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
  ];

  options.mySystem.persistentFolder = lib.mkOption {
    type = lib.types.str;
    description = "persistent folder for nixos mutable files";
    default = "/persist/nixos";
  };

  options.mySystem.nasFolder = lib.mkOption {
    type = lib.types.str;
    description = "folder where nas mounts reside";
    default = "/mnt/nas";
  };
  options.mySystem.domain = lib.mkOption {
    type = lib.types.str;
    description = "domain for hosted services";
    default = "";
  };
  options.mySystem.internalDomain = lib.mkOption {
    type = lib.types.str;
    description = "domain for local devices";
    default = "";
  };

  config = {
    systemd.tmpfiles.rules = [
      "d ${config.mySystem.persistentFolder} 777 - - -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];
  };
}
