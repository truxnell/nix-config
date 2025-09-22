{ pkgs, config, ... }:
let
  # useful shortcuts
  reboot-uefi = pkgs.writeTextDir
    "share/applications/reboot-uefi.desktop" # ini

    ''
      [Desktop Entry]
      Name=Steam Session
      Exec=sudo systemctl reboot --firmware-setup
      Type=Application
    '';
in
with config;
{
  imports = [
    ./global.nix
  ];


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
        pikvm = {
          hostname = "pikvm";
          port = 22;
          user = "root";
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


  myHome = {
    programs = {
      firefox.enable = true;
      thunderbird.enable = true;
    };
    shell = {

      starship.enable = true;
      fish.enable = true;
      wezterm.enable = true;

    };
  };
  home = {
    # Install these packages for my user
    packages = with pkgs;
      [
        #apps
        discord
        steam
        lutris
        spotify
        unstable.prusa-slicer
        bitwarden
        yubioath-flutter
        yubikey-manager-qt
        flameshot
        vlc
        ffmpeg
        pinta
        gimp

        # cli
        bat
        dbus
        direnv
        git
        nix-index
        python3
        fzf
        ripgrep
        jq
        yq
        unrar
        p7zip


        brightnessctl

        # office
        thunderbird
        unstable.onlyoffice-bin
        evince # pdf viewer
        # logseq nixpkgs ver is PITA
        pinta
        gimp

        #shortcuts
        reboot-uefi

        # split out to emulation hm
        nsz
        ryujinx
        # 
        steam-rom-manager


        #wiiu
        cemu
        cdecrypt



      ];

  };

}
