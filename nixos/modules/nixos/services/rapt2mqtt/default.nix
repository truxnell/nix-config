{ lib
, config
, pkgs
, ...
}:
with lib;
let
  rapt2mqtt = pkgs.writeText "rapt2mqtt.py" (builtins.readFile ./rapt2mqtt.py);
  cfg = config.mySystem.${category}.${app};
  app = "rapt2mqtt";
  category = "services";
  description = "";
  image = "";
  user = "root"; #string
  group = "root"; #string
  port = 0; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
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
    sops.secrets."${category}/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    systemd.services.rapt2mqtt = {
      description = "rapt2mqtt";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target"  ];
      startAt = "hourly";
      serviceConfig = {
        Restart = "on-failure";
        User = user;
        EnvironmentFile = [ config.sops.secrets."${category}/${app}/env".path ];
        # https://github.com/sgoadhouse/rapt-mqtt-bridge
        ExecStart = let
        python = pkgs.python3.withPackages (ps: with ps; [ paho-mqtt requests python-dateutil ]);
        in
          "${python.interpreter} ${rapt2mqtt} -n 15 -f -s -v 1";

      };
    };


  };
}
