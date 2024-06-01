{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "frigate";
  category = "services";
  description = "Camera object detection";
  image = "ghcr.io/blakeblackshear/frigate:0.13.2@sha256:2906991ccad85035b176941f9dedfd35088ff710c39d45ef1baa9a49f2b16734";
  user = "kah"; #string
  group = "kah"; #string
  port = 5000; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
  frigateSettings = import ./settings.nix;
  configFile = pkgs.writeText "frigate.yml" (generators.toYAML { } frigateSettings);
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
      group = group;
      restartUnits = [ "${app}.service" ];
    };

    users.users.truxnell.extraGroups = [ group ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    };

    virtualisation.oci-containers.containers.${app} = {
      image = "${image}";
      user = "0:0";
      environment = {
        LIBVA_DRIVER_NAME = "i965";
      };
      volumes = [
        "/dev/bus/usb:/dev/bus/usb" # req for coral USB
        "/dev/dri/renderD128:/dev/dri/renderD128"
        "${appFolder}:/data:rw"
        "${configFile}:/config/config.yml:ro"
        "${config.mySystem.nasFolder}/frigate:/media:rw"
      ];
      extraOptions = [
        "--mount=type=tmpfs,target=/dev/shm,tmpfs-size=1000000000"
        "--cap-add=CHOWN"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
        "--cap-add=DAC_OVERRIDE"
        "--privileged"
        "--mount=type=tmpfs,target=/tmp/cache,tmpfs-size=1000000000"
        "--cap-add=CAP_PERFMON"
        "--shm-size=128m"
      ];
      ports = [ "5000:5000" "8554:8554" "8555:8555/tcp" "8555:8555/udp" ]; # expose port

      environmentFiles = [ config.sops.secrets."${category}/${app}/env".path ];
    };


    ## service
    # services.frigate = {
    #   enable = true;
    #   hostname = url; # use nix option for nginx ingress due to complexity
    #   settings = {
    #     detectors.coral =
    #       {
    #         type = "edgetpu";
    #         device = "usb";
    #       };
    #     go2rtc.streams = {
    #       midgarden = "rtspx://10.8.10.1:7441/YejyBzbcJftkgMSA";
    #       backgarden = "rtspx://10.8.10.1:7441/brWeoAmzSap1eSn0";
    #     };
    #     cameras = {
    #       midgarden = {
    #         objects.track = [ "person" ];
    #         ffmpeg.inputs = [
    #           {
    #             path = "rtsp://127.0.0.1:8554/midgarden";
    #             roles = [ "detect" ];
    #           }
    #         ];
    #       };
    #       backgarden = {
    #         objects.track = [ "person" ];
    #         ffmpeg.inputs = [
    #           {
    #             path = "rtsp://127.0.0.1:8554/backgarden";
    #             roles = [ "detect" ];
    #           }
    #         ];
    #       };
    #     };
    #   };
    # };

    # # https://github.com/NixOS/nixpkgs/issues/188719#issuecomment-1774169734
    # systemd.services.frigate.environment.LD_LIBRARY_PATH = "${pkgs.libedgetpu}/lib";
    # systemd.services.frigate.serviceConfig = {
    #   SupplementaryGroups = "plugdev";
    # };
    # services.udev.packages = [ pkgs.libedgetpu ];
    # users.groups.plugdev = { };

    # services.go2rtc = {
    #   enable = true;
    #   settings.streams = config.services.frigate.settings.go2rtc.streams;
    # };

    services.nginx.virtualHosts."${app}.${config.networking.domain}" = {
      useACMEHost = config.networking.domain;
      forceSSL = true;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
        proxyWebsockets = true;
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
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
      }
    ];

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


  };
}
