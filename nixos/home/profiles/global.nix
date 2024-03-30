{ lib, pkgs, self, config, ... }:
with lib;
{

  config = {

    services.gpg-agent.pinentryPackage = pkgs.pinentry-qt;

    # # often hangs
    # systemd.services.systemd-networkd-wait-online.enable = false;
    # systemd.services.NetworkManager-wait-online.enable = false;

    # Home-manager nixpkgs config
    nixpkgs = {

      # Allow "unfree" licenced packages
      config = { allowUnfree = true; };

      overlays = [
        self.overlays.default
      ];
    };
  };
}
