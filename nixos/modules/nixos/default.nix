{ lib, ... }:
{
  imports = [
    ./system
    ./programs
    ./services
    ./browser
    ./de
    ./editor
    ./hardware
    ./containers
  ];

  options.mySystem.persistentFolder = lib.mkOption {
    type = lib.types.str;
    description = "persistent folter for mutable files";
    default = "/persist/nixos/";
  };

  options.mySystem.nasFolder = lib.mkOption {
    type = lib.types.str;
    description = "folder where nas mounts reside";
    default = "/mnt/nas";
  };

}
