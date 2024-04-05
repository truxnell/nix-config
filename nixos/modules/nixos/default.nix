{ lib, ... }:
{
  imports = [
    ./system
    ./programs
    ./services
    ./browser
    ./de
    ./editor
    ./containers
    ./hardware
  ];

  options.mySystem.persistentFolder = lib.mkOption {
    type = lib.types.str;
    description = "persistent folter for mutable files";
    default = "/persistent/nixos/";
  };

}
