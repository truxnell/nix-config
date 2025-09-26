{ lib
, config
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
        default = "/var/lib/syncthing";
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
      dataDir = cfg.dataDir;
      settings = {
        options.urAccepted = -1;
        devices =
          {
            # TODO secret lul
            "Nat Pixel 6Pro" = { id = "M7LCNZI-CCAFOXA-LD55CRE-O7DXKBB-H3MXOLV-2LUQBRC-VAFOCJO-A5DNJQW"; };
            "daedalus" = { id = "HJOBCTW-NZHZLUU-HOUBWYC-R3MX3PL-EI4R6PN-74RN7EW-UBEUY7H-TNMEPQB"; };
            "rickenbacker" = { id = "WTL2NPD-QDY26QZ-NNGRK7R-Z6A7U67-3RBP5PN-BE2VO2V-XFQMT7H-3LMZKQH"; };
            "citadel" = { id = "OPJO4SQ-ZWGUZXL-XHF25ES-RNLF5TR-AOEY4O6-2TJEFU5-AVDOQ52-AOSJWAI"; };
            "citadel-bazzite" = { id = "VJ4IMR3-HDZISJJ-BVM5LIN-BOHYS6M-F4AE6JY-TCK6KH4-DLNWI5I-WP5OSQI"; };
            "steam-deck" = { id = "4TD66JX-TO4NBCX-2HSAXJL-JK43SVI-F5QYEWU-GTDPUNQ-BTLAM7Z-DLTEOAR"; };
          };
        folders = {
          "pixel_6_pro_j4mw-photos" = {
            path = "${cfg.syncPath}/android_photos";
            devices = [ "Nat Pixel 6Pro" ];
          };
          "logseq" = {
            path = "${cfg.syncPath}/logseq";
            devices = [ "Nat Pixel 6Pro" "daedalus" "rickenbacker" "citadel" "citadel-bazzite" ];
          };
          "mobile" = {
            path = "${cfg.syncPath}/mobile";
            devices = [ "Nat Pixel 6Pro" "daedalus" "rickenbacker" "citadel" "citadel-bazzite" ];
          };
          "emulation" = {
            path = "${cfg.syncPath}/emulation";
            devices = [ "daedalus" "steam-deck" "citadel-bazzite" ];
          };
          "Mackup" = {
            path = "${cfg.syncPath}/Mackup";
            devices = [ "daedalus" "citadel-bazzite" "rickenbacker" ];
          };

        };
      };
    };



    ### gatus integration
    # mySystem.services.gatus.monitors = mkIf cfg.monitor [
    #   {
    #     name = app;
    #     group = "${category}";
    #     url = "https://${url}";
    #     interval = "1m";
    #     conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 1500" ];
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
