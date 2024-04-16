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
  configDir = pkgs.writeTextDir "pdns.conf" "${pdnsConfig}";
  pdnsConfig = ''
    expand-alias=yes
    resolver=9.9.9.9:53
    local-address=0.0.0.0:5353
    launch=gsqlite3
    gsqlite3-database=${persistentFolder}/pdns.sqlite3
    webserver=yes
    webserver-address=0.0.0.0:8081
    webserver-allow-from=10.8.10.0/20

  '';
in
{
  options.mySystem.services.powerdns =
    {
      enable = mkEnableOption "powerdns";
      openFirewall = mkEnableOption "Open firewall for ${app}" // {
        default = true;
      };
    };

  config = mkIf cfg.enable {

    # ensure folder exist and has correct owner/group
    systemd.tmpfiles.rules = [
      "d ${persistentFolder} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period
    ];

    # wget https://raw.githubusercontent.com/PowerDNS/pdns/master/modules/gsqlite3backend/schema.sqlite3.sql
    # sqlite3 /persistent/nixos/pdns/pdns.sqlite3 < schema.sqlite3.sql
    # rm schema.sqlite3.sql

    environment.systemPackages = with pkgs;
      [ sqlite wget ];

    environment.etc.pdns.source = configDir;

    systemd.packages = [ pkgs.pdns ];

    systemd.services.pdns = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "mysql.service" "postgresql.service" "openldap.service" ];

      serviceConfig = {
        ExecStartPre = (pkgs.writeScript
          "pdns-sqlite-init.sh"
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
        );
        ExecStart = [ "" "${pkgs.pdns}/bin/pdns_server --config-dir=${configDir} --guardian=no --daemon=no --disable-syslog --log-timestamp=no --write-pid=no" ];
      };
    };

    users.users.pdns = {
      isSystemUser = true;
      group = "pdns";
      description = "PowerDNS";
    };

    users.groups.pdns = { };

    networking.firewall = mkIf cfg.openFirewall {

      allowedTCPPorts = [ 8081 5353 ];


    };


  };
}
