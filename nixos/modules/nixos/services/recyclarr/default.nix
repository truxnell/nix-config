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
  # image = "";
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
      group = group;
      restartUnits = [ "${app}.service" ];
    };

    ## service
    systemd.services.recyclarr = {
      description = "Recyclarr Sync Service";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [ config.sops.secrets."${category}/${app}/env".path ];
        ExecStart = "${pkgs.recyclarr}/bin/recyclarr sync --config ${recyclarrYaml} --app-data /tmp -d";
        User = user;
        Group = group;
        PrivateTmp = "true";
      };
    };

    systemd.timers.recyclarr = {
      description = "Recyclarr Sync Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = [ "weekly" ];
        Persistent = true;
      };
    };

  };
}
