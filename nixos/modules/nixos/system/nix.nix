{ lib
, config
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.nix;
in
{
  options.mySystem.nix = {
    autoOptimiseStore = mkOption
      {
        type = lib.types.bool;
        description = "If we want to auto optimise store";
        default = true;

      };
    gc = {
      enabled = mkEnableOption "automatic garbage collection" // {
        default = true;
      };
      persistent = mkOption
        {
          type = lib.types.bool;
          description = "Persistent timer for gc, runs at startup if timer missed";
          default = true;
        };
    };

  };

  nix = {

    optimise.automatic = cfg.autoOptimiseStore;

    # automatically garbage collect nix store
    gc = mkIf cfg.gc.enabled {
      # garbage collection
      automatic = cfg.gc.enabled;
      options = "--delete-older-than 30d";
      persistent = cfg.gc.persistent;
    };

  };


}
