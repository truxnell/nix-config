{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.traefik;
in
{
  options.mySystem.services.traefik.enable = mkEnableOption "Traefik reverse proxy";

  config = mkIf cfg.enable {

    services.traefik = {
      enable = true;
      staticConfigOptions = {
        api.dashboard = true;
        api.insecure = true;

        serversTransport = {
          # Disable backend certificate verification.
          insecureSkipVerify = true;
        };
      };
    };
  };
}
