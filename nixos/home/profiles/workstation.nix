{ lib, pkgs, self, config, ... }:
with config;
{

  home = {
    # Install these packages for my user
    packages = with pkgs; [
      discord
      steam
      spotify
      brightnessctl

      bat
      dbus
      direnv
      git
      nix-index
      python3
      fzf
      ripgrep

    ];

  };
}
