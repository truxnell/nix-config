{ lib
, config
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.system;
in
{
  options.mySystem.system.packages = {
    autoOptimiseStore = mkOption
      {
        type = lib.types.list;
        description = "List of system level package installs";
        default = [ ];
      };
  };

  # System packages deployed globally.
  # This is NixOS so lets keep this liiight?
  # Ideally i'd keep most of it to home-manager user only stuff
  # and keep server role as light as possible
  config.environment.system.packages = cfg.packages;

}
