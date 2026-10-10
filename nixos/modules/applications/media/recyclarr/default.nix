{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "recyclarr";
  category = "services";
  description = "TRaSH guides sync";
  image = "ghcr.io/recyclarr/recyclarr:8.7.3@sha256:9c6c74d52cfc6f740a5a3624aa83867e171bb70b90453ddb7a4048b8c80445f9";
  user = "kah"; # string
  group = "kah"; # string #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  # recyclarrYaml = (pkgs.formats.yaml { }).generate "recyclarr.yml" (recyclarrNix);
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };

  };

  config = mkIf cfg.enable {

    ## Secrets
    ## env files MUST be in format
    ## VAR="derp"
    ## not VAR=derp
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [
            {
              directory = appFolder;
              inherit user group;
              mode = "755";
            }
          ];
        };

    systemd.services."recyclarr" =

      {
        script = ''
          ${pkgs.podman}/bin/podman run --rm \
          --user 568:568 \
          -v ${config.sops.secrets."${category}/${app}/env".path}:/config/recyclarr.yml:ro \
          -v ${appFolder}:/data:rw \
          ${image} \
          sync \
          -c /config/recyclarr.yml \
          --app-data /data \
          -d
        '';
        path = [ pkgs.podman ];
        requires = [
          "sonarr.service"
          "radarr.service"
        ];
        startAt = "daily";

      };

  };
}
