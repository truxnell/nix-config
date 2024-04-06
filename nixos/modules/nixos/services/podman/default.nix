{ lib
, config
, pkgs
, ...
}:

with lib;
let
  cfg = config.mySystem.services.podman;
in
{
  options.mySystem.services.podman.enable = mkEnableOption "Podman";

  config = mkIf cfg.enable
    {
      virtualisation.podman = {
        enable = true;

        dockerCompat = true;
        extraPackages = [ pkgs.zfs ];
        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };
      virtualisation.oci-containers = {
        backend = "podman";
      };
      networking.firewall.interfaces.podman0.allowedUDPPorts = [ 53 ];


    };

}
