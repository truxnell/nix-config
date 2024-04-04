{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.nix-serve;
in
{
  options.mySystem.services.nix-serve.enable = mkEnableOption "nix-serve";

  # enable nix serve binary cache
  # you can test its working with `nix store ping --store http://10.8.20.33:5000`
  config.services.nix-serve = mkIf cfg.enable {

    enable = true;
    package = pkgs.nix-serve-ng;
    openFirewall = true;

  };


}
