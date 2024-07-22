{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "syncthing";
  category = "services";
  description = "File syncing service";
  # image = "";
  inherit (config.services.syncthing) user;#string
  inherit (config.services.syncthing) group;#string
  port = 8384; #int
  appFolder = config.services.syncthing.configDir;
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
      dataDir = lib.mkOption {
        type = lib.types.str;
      };
      syncPath = lib.mkOption {
        type = lib.types.str;
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "syncthing";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "users";
      };
    };

  config = mkIf cfg.enable {

    ## Secrets
    # sops.secrets."${category}/${app}/env" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = user;
    #   group = group;
    #   restartUnits = [ "${app}.service" ];
    # };

    users.users.truxnell.extraGroups = [ group ];


    # Folder perms - only for containers
    systemd.tmpfiles.rules = [
      "d ${appFolder}/ 0750 ${user} ${group} -"
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };


    ## service
    # Ref: https://wes.today/nixos-syncthing/
    #
    # First run may need settings omitted, then a setting changed in webui and saved
    # just to create the config.xml file that the syncthing-init file needs
    #
    services.syncthing = {
      enable = true;
      group = cfg.group;
      guiAddress = "0.0.0.0:8384";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      user = cfg.user;

      settings = {
        options.urAccepted = -1;
        devices = {
          "Nat Pixel 6Pro" = { id = "OMARXQ7-KTMH2EB-BAIU7LO-VJB6Q5Z-D6GAAAA-75J4I5D-Q7XPGTI-K34WEQR"; };
          "daedalus" = { id = "HJOBCTW-NZHZLUU-HOUBWYC-R3MX3PL-EI4R6PN-74RN7EW-UBEUY7H-TNMEPQB"; };
          "rickenbacker" = { id = "TFUS4NM-RCCKPUD-NDR5S7Z-DYAAMF4-G6GQPC2-7I6EGSD-NHJ5YKG-N3EHIQL"; };
        };
        folders = {
          "pixel_6_pro_vq13-photos" = {
            path = "${cfg.syncPath}/android_photos";
            devices = [ "Nat Pixel 6Pro"  ];
          };
          "logseq" = {
            path = "${cfg.syncPath}/logseq";
            devices = [ "Nat Pixel 6Pro" "daedalus" "rickenbacker" ];
          };

        };
      };
    };

    # homepage integration
    mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
      {
        ${app} = {
          icon = "${app}.svg";
          href = "https://${url}";
          inherit description;
        };
      }
    ];

    ### gatus integration
    # mySystem.services.gatus.monitors = mkIf cfg.monitor [
    #   {
    #     name = app;
    #     group = "${category}";
    #     url = "https://${url}";
    #     interval = "1m";
    #     conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
    #   }
    # ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    warnings = [
      (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
        "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (config.lib.mySystem.mkRestic
      {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      });


    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };



  };
}
