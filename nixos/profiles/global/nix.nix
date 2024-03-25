{ lib, config, ... }:
{


  nix.settings = {
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




}
