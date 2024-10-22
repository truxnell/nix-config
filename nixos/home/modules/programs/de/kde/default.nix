# Adjusted manually from generated output of dconf2nix
# https://github.com/gvolpe/dconf2nix
{ lib
, pkgs
, osConfig
, ...
}:
with lib.hm.gvariant; {

  config = lib.mkIf osConfig.mySystem.de.kde.enable {
    # add user packages
    home.packages = with pkgs;  [
      kdePackages.kalk

    ];

  };
}
