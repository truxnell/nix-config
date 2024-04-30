{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.powerdns;
  persistentFolder = "${config.mySystem.persistentFolder}/nixos/pdns";
  user = "pdns";
  group = "pdns";
  portDns = 5353; # avoiding conflict with adguardhome
  portWebUI = 8081;
  configDir = pkgs.writeTextDir "pdns.conf" "${pdnsConfig}";

  # $APIKEY is replaced via envsubst in the pdns module
  pdnsConfig = ''
    expand-alias=yes
    resolver=9.9.9.9:53
    local-address=0.0.0.0:${builtins.toString portDns}
    launch=gsqlite3
    gsqlite3-database=${persistentFolder}/pdns.sqlite3
    webserver=yes
    webserver-address=0.0.0.0:${builtins.toString portWebUI}
    webserver-allow-from=10.8.10.0/20
    api=yes
    api-key=$APIKEY
  '';
in
{
  options.mySystem.services.powerdns =
    {
      enable = mkEnableOption "powerdns";
      openFirewall = mkEnableOption "Open firewall for ${app}" // {
        default = true;
      };
      admin-ui = mkEnableOption "Powerdns-admin UI";
    };

  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0750 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    services.powerdns = {
      enable = true;
      extraConfig = pdnsConfig;
      secretFile = config.sops.secrets."system/services/powerdns/apiKey".path;
    };
    sops.secrets."system/services/powerdns/apiKey" = {
      sopsFile = ./secrets.sops.yaml;
      restartUnits = [ "pdns.service" ];
    };

    # powerdns doesnt create the sqlite database for us
    # so we gotta either do it manually once-off or do the below to ensure its created
    # if the file is missing before service start
    systemd.services.pdns.serviceConfig.ExecStartPre = lib.mkBefore [
      (pkgs.writeScript "pdns-sqlite-init.sh"
        ''
          #!${pkgs.bash}/bin/bash

          pdns_folder="${persistentFolder}"
          echo "INIT: Checking if pdns sqlite exists"
          # Check if the pdns.sqlite3 file exists in the pdns folder
          if [ ! -f "${persistentFolder}/pdns.sqlite3" ]; then
              echo "INIT: No sqlite db found, initializing from pdns github schema..."

              ${pkgs.wget}/bin/wget -O "${persistentFolder}/schema.sqlite3.sql" https://raw.githubusercontent.com/PowerDNS/pdns/master/modules/gsqlite3backend/schema.sqlite3.sql
              ${pkgs.sqlite}/bin/sqlite3 "${persistentFolder}/pdns.sqlite3" < "${persistentFolder}/schema.sqlite3.sql"
              ${pkgs.busybox}/bin/chown pdns:pdns ${persistentFolder}/pdns.sqlite3
              ${pkgs.busybox}/bin/rm "${persistentFolder}/schema.sqlite3.sql"
          fi

          # Exit successfully
          exit 0

        ''
      )
    ];

    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ portWebUI portDns ];
      allowedUDPPorts = [ portDns ];

    };

    mySystem.services.gatus.monitors = [

      {
        name = "${config.networking.hostName} split DNS";
        group = "dns";
        url = "${config.networking.hostName}.${config.mySystem.internalDomain}:${builtins.toString portDns}";
        dns = {
          query-name = "canary.trux.dev"; # special domain always present for testing
          query-type = "A";
        };
        interval = "1m";
        alerts = [{ type = "pushover"; }];
        conditions = [ "[DNS_RCODE] == NOERROR" ];
      }
    ];



  };
}
