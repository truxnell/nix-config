{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.home-assistant;
  app = "Home-assistant";
  user = "kah";
  group = "kah";
  appFolder = "home-assistant";
  persistentFolder = "${config.mySystem.persistentFolder}/containers/${appFolder}";

in
{
  options.mySystem.services.home-assistant.enable = mkEnableOption "home-assistant";

  # running in a container vs nix module mainly
  # as I know the container is solid. Bit iffy
  # over the packaging of HA in nix & arguments
  # from HA dev on nix packaging
  config = mkIf cfg.enable
    (lib.recursiveUpdate
      {
        sops.secrets."services/${app}/env" = {
          sopsFile = ./secrets.sops.yaml;
          owner = user;
          inherit group;
          restartUnits = [ "podman-${app}.service" ];
        };
      }

      (myLib.mkService
        {
          inherit app user group;
          description = "Home Automation";
          port = 8123;
          inherit (config.time) timeZone;
          # subdomainOverride = "hass";
          inherit (config.networking) domain;
          persistence = {
            folder = persistentFolder;
            backup = true;
          };
          homepage = {
            icon = "home-assistant.svg";
            category = "home";
          };
          container = {
            enable = true;
            image = "ghcr.io/onedr0p/home-assistant:2024.1.5@sha256:64bb3ffa532c3c52563f0e4a4de8d50c889f42a1b0826b35ee1ac728652fb107";
            env = {
              HASS_IP = "10.8.20.42";
            };
            envFiles = [ config.sops.secrets."services/${app}/env".path ];
            persistentFolderMount = "/config";
            addTraefikLabels = true;
            caps = {
              # readOnly = true;
              noNewPrivileges = true;
              # dropAll = true;
            };
          };
        })
    );
}
