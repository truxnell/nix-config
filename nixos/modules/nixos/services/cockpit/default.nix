{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.mySystem.services.cockpit;
in
{
  options.mySystem.services.cockpit.enable = mkEnableOption "Cockpit";

  config.services.cockpit = mkIf cfg.enable {
    enable = true;
    openFirewall = true;
    package = pkgs.cockpit.overrideAttrs (old: {
      # remove packagekit and selinux, don't work on NixOS
      postBuild = ''
        ${old.postBuild}

        rm -rf \
          dist/packagekit \
          dist/selinux
      '';
    });
  };

  config.environment = mkIf cfg.enable {
    systemPackages = with pkgs;
      [
        (mkIf config.virtualisation.podman.enable nur.repos.procyon.cockpit-podman) # only if server runs pods

        # nur.repos.dukzcry.cockpit-machines # TODO enable with virtualisation on server
        # nur.repos.dukzcry.libvirt-dbus # TODO enable with virtualisation on server
        # pkgs.virt-manager # TODO enable with virtualisation on server
      ];



  };
}
