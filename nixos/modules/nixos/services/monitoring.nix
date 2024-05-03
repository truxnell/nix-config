{ lib
, config
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.services.promMonitoring;
in
{
  options.mySystem.services.promMonitoring.enable = mkEnableOption "Prometheus Monitoring";

  config = mkIf cfg.enable {

    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
          "time"
          "uname"
          "systemd"
        ];
      };
      smartctl = {
        enable = true;
      };


    };

    # ensure ports are open
    networking.firewall.allowedTCPPorts = mkIf cfg.enable [
      config.services.prometheus.exporters.node.port
      config.services.prometheus.exporters.smartctl.port
    ];

    mySystem.monitoring.prometheus.scrapeConfigs = [
      {
        job_name = "node-exporter-${config.networking.hostName}";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];

  };

}
