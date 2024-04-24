{ lib, pkgs, self, config, inputs, ... }:
with config;
{
  imports = [
    ./global.nix
  ];

  myHome.programs.firefox.enable = true;

  myHome.security = {
    ssh = {
      #TODO make this dynamic
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
        durandal = {
          hostname = "durandal";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };

        daedalus = {
          hostname = "daedalus";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        shodan = {
          hostname = "shodan";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };

      };
    };
  };

  myHome.shell = {

    starship.enable = true;
    fish.enable = true;
    wezterm.enable = true;

    git = {
      enable = true;
      username = "truxnell";
      email = "19149206+truxnell@users.noreply.github.com";
      # signingKey = ""; # TODO setup signing keys n shit
    };

  };





  home = {
    # Install these packages for my user
    packages = with pkgs;
      [
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
        flyctl # fly.io control line

      ];

  };
}
