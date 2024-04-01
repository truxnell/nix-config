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

  config = mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # TEST
    virtualisation.oci-containers.containers = {
      container-name = {
        image = "docker/getting-started";
        autoStart = true;
        ports = [ "0.0.0.0:8081:80" ];
      };
    };
    networking = {
      firewall.allowedTCPPorts = [ 8081 ];
    };

  };


}
