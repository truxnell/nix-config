{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.homeassistant;
in
{
  options.mySystem.services.homeassistant.enable = mkEnableOption "homeassistant";

  # running in a container vs nix module mainly
  # as i now the container is solid and bit iffy
  # over the packaging of HA in nix
  config =
    mkIf cfg.enable
      (myLib.mkService
        {
          app = "HomeAssistant";
          description = "Home Automation";
          image = "ghcr.io/onedr0p/home-assistant:2024.1.5@sha256:64bb3ffa532c3c52563f0e4a4de8d50c889f42a1b0826b35ee1ac728652fb107";
          port = 8123;
          user = "568";
          group = "568";
          timeZone = config.time.timeZone;
          domain = config.networking.domain;
          addToHomepage = true;
          homepage.icon = "homeassistant.svg";
          homepage.category = "home";
          container = {
            env = {
              HASS_IP="10.8.20.42";

            };
            addTraefikLabels = true;
            caps = {
              readOnly = true;
              noNewPrivileges = true;
              dropAll = true;
            };
          };
        });
}
