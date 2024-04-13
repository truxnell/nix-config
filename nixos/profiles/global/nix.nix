{ lib, config, pkgs, nixpkgs, self, ... }:
{
  ## Below is to align shell/system to flake's nixpkgs
  ## ref: https://nixos-and-flakes.thiscute.world/best-practices/nix-path-and-flake-registry

  # Make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake.
  environment.etc."nix/inputs/nixpkgs".source = "${nixpkgs}";
  nix = {

    # make `nix run nixpkgs#nixpkgs` use the same nixpkgs as the one used by this flake.
    registry.nixpkgs.flake = nixpkgs;
    channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

    # but NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake.
    # https://github.com/NixOS/nix/issues/9574
    settings.nix-path = lib.mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";

    ###

    settings = {

      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Substitutions
      substituters = [
        "https://cache.garnix.io"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];

      # Fallback quickly if substituters are not available.
      connect-timeout = 25;
      # Avoid copying unnecessary stuff over SSH
      builders-use-substitutes = true;


      trusted-users = [ "root" "@wheel" ];

      warn-dirty = false;

      # The default at 10 is rarely enough.
      log-lines = lib.mkDefault 25;

    };
  };

}
