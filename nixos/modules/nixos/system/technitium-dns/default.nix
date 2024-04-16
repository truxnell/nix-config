{ lib
, config
, pkgs
, ...
}:
with lib;
let

  stateDir = "/var/lib/technitium-dns-server";
  cfg = config.mySystem.system.technitium-dns;
in
{
  options.mySystem.system.technitium-dns.enable = mkEnableOption "technitium-dns";

  config = mkIf cfg.enable {

    networking.firewall = {
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [
        53
        80
        443
        5380
        53443
      ];
    };

    systemd.services.technitium-dns-server = {
      description = "Technitium DNS Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.unstable.technitium-dns-server}/bin/technitium-dns-server ${stateDir}";

        User = "technitiumdns";
        Group = "technitiumdns";

        StateDirectory = "technitium-dns-server";
        WorkingDirectory = stateDir;
        BindPaths = stateDir;

        Restart = "always";
        RestartSec = 10;
        TimeoutStopSec = 10;
        KillSignal = "SIGINT";

        # Harden the service
        LockPersonality = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX AF_NETLINK";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;

        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };
    };

    users = {
      users = {
        technitiumdns = {
          group = "technitiumdns";
          isSystemUser = true;
        };
      };
      groups = {
        technitiumdns = { };
      };
    };

  };
}
