{ pkgs
, config
, lib
, ...
}:
let
  cfg = config.mySystem.services.glances;
  app = "Glances";
in
with lib;
{
  options.mySystem.services.glances =
    {
      enable = mkEnableOption "Glances system monitor";
      monitor = mkOption
        {
          type = lib.types.bool;
          description = "Enable gatus monitoring";
          default = true;

        };
      addToHomepage = mkOption
        {
          type = lib.types.bool;
          description = "Add to homepage";
          default = true;

        };

    };
  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs;
      [ glances python310Packages.psutil hddtemp ];

    # port 61208
    systemd.services.glances = {
      script = ''
        ${pkgs.glances}/bin/glances --enable-plugin smart --webserver --bind 0.0.0.0
      '';
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    networking = {
      firewall.allowedTCPPorts = [ 61208 ];
    };


    environment.etc."glances/glances.conf" = {
      text = ''
        [global]
        check_update=False

        [network]
        hide=lo,docker.*

        [diskio]
        hide=loop.*

        [containers]
        disable=False
        podman_sock=unix:///var/run/podman/podman.sock

        [connections]
        disable=True

        [irq]
        disable=True
      '';
    };

    mySystem.services.gatus.monitors = mkIf cfg.monitor [{

      name = "${app} ${config.networking.hostName}";
      group = "${app}";
      url = "http://${config.networking.hostName}.${config.mySystem.internalDomain}:61208:/api/3/status";

      interval = "1m";
      conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    }];

    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        "Glances ${config.networking.hostName}" = {
          icon = "${app}.svg";
          href = "http://${config.networking.hostName}.${config.mySystem.internalDomain}:61208";
          description = "System Monitoring";
          container = "Infrastructure";
        };
      }
    ];
  };
}
