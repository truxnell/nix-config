{
  config,
  pkgs,
  lib,
  ...
}: {
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

  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
    config.services.prometheus.exporters.smartctl.port
  ];
}
