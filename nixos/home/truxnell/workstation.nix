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

  myHome.security = {
    ssh = {
      enable = true;
      matchBlocks = {
        citadel = {
          hostname = "citadel";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        rickenbacker = {
          hostname = "rickenbacker";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        dns01 = {
          hostname = "dns01";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        dns02 = {
          hostname = "dns02";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        pikvm = {
          hostname = "pikvm";
          port = 22;
          user = "root";
          identityFile = "~/.ssh/id_ed25519";
        };

      };
    };
  };

  home = {
    # Install these packages for my user
    packages = with pkgs; [
      discord
      steam
      spotify
      brightnessctl
      prusa-slicer
      bitwarden
      yubioath-flutter
      yubikey-manager-qt

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
