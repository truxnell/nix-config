{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "recyclarr";
  category = "services";
  description = "TRaSH guides sync";
  image = "ghcr.io/recyclarr/recyclarr:7.4.0@sha256:c3a46c4e6afb5e1e7b1f7307dd38a5cd7cc47994eee0b4d8e3b7d5d929120881";
  user = "kah"; #string
  group = "kah"; #string
  port = 8000; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";

  recyclarrNix = {
    sonarr = import ./sonarr.nix;
    radarr = import ./radarr.nix;
  };
  # recyclarrYaml = (pkgs.formats.yaml { }).generate "recyclarr.yml" (recyclarrNix);
  recyclarrYaml = pkgs.writeTextFile { name = "config.yml"; text = builtins.readFile ./config.yml; };
in
{
  options.mySystem.${category}.${app} =
    {
      enable = mkEnableOption "${app}";
      addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;
        };
      prometheus = mkOption
        {
          type = lib.types.bool;
          description = "Enable prometheus scraping";
          default = true;
        };
      addToDNS = mkOption
        {
          type = lib.types.bool;
          description = "Add to DNS list";
          default = true;
        };
      dev = mkOption
        {
          type = lib.types.bool;
          description = "Development instance";
          default = false;
        };
      backup = mkOption
        {
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

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user group; mode="755"; }];
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
        requires = [ "sonarr.service" "radarr.service" ];
        startAt = "daily";

      };

  };
}
