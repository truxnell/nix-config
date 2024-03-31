{ lib, pkgs, self, config, ... }:
with config;
{
  imports = [
    ./global.nix
  ];

  myHome.programs.firefox.enable = true;
  myHome.shell.starship.enable = true;
  myHome.shell.fish.enable = true;
  myHome.shell.wezterm.enable = true;

  home = {
    # Install these packages for my user
    packages = with pkgs; [
      discord
      steam
      spotify
      brightnessctl
      prusa-slicer
      bitwarden

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
