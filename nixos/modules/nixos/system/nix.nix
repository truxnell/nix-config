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
    settings = {
      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Substitutions
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];

      # Fallback quickly if substituters are not available.
      connect-timeout = 5;
      # Avoid copying unnecessary stuff over SSH
      builders-use-substitutes = true;


      trusted-users = [ "root" "@wheel" ];

      warn-dirty = false;

      # The default at 10 is rarely enough.
      log-lines = lib.mkDefault 25;

    };

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
