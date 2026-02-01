# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./storage.nix

  ];
  config = {

    mySystem.purpose = "Network Attached Storage";
    # mySystem.system.impermanence.enable = true;
    mySystem.system.autoUpgrade.enable = true; # bold move cotton

    services.postgresqlBackup = {
      location = lib.mkForce "/zfs/backup/nixos/postgresql";
    };

    mySystem.services = {
      # Infrastructure
      # Databases
      postgresql.enable = true;
      # System
      openssh.enable = true;
      podman.enable = true;
      # Storage
      minio.enable = true;
      # Web server
      nginx.enable = true;

      # Monitoring
      loki.enable = true;
      loki.retention = "720h"; # 30 days
      promtail.enable = true;
      mcp-grafana.enable = true;

      # Media
      # Media servers
      plex.enable = true;
      jellyfin.enable = true;
      jellyseer.enable = true;
      # Arr stack
      sonarr.enable = true;
      radarr.enable = true;
      recyclarr.enable = true;
      lidarr.enable = true;
      readarr.enable = true;
      # Torrent stack
      qbittorrent.enable = true;
      qbittorrent-lts.enable = true;
      sabnzbd.enable = true;
      
      # cross-seed.enable = true; #QUI handles this now
      # Media automation
      prowlarr.enable = true;
      autobrr.enable = true;
      # Music
      navidrome.enable = true;
      
      # Comics
      kavita.enable=true;
      # Productivity
      # Documentation
      paperless.enable = true;
      trilium.enable = true;
      # Tools
      # tandoor.enable = true;
      open-webui.enable = true;
      atuin.enable = true;
      # Communication
      redbot.enable = true;

      # Storage
      syncthing = {
        enable = true;
        syncPath = "/zfs/syncthing/";
      };
      # Deprecated, have to move to docker setup
      # seafile = {
      #   enable = true;
      #   fileLocation = "/zfs/seafile";
      # };

      # Development
      forgejo.enable = true;

      # Networking
      technitium-dns-server.enable = true;

      # Misc
      immich.enable = true;
      ntfy.enable = true;
      # qbit-tqm.enable = true; #qui handles this
      qui.enable = true;
      # maintainerr.enable = true;
      # filebrowser.enable = true;
      # jellyseer.enable = true;
      # glance.enable = true;
    };
    mySystem.security.acme.enable = true;

    mySystem.nasFolder = "/tank";
    mySystem.system.resticBackup.local.location = "/zfs/backup/nixos/nixos";

    mySystem.system = {
      zfs.enable = true;
      zfs.mountPoolsAtBoot = [ "zfs" ];
    };

    mySystem.services.nfs.enable = true;
    mySystem.system.motd.networkInterfaces = [ "eno2" ];

    # TODO abstract out?

    # Intel qsv
    boot.kernelParams = [
      "i915.enable_guc=2"
    ];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };

    boot = {

      initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "mpt3sas"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];

      # for managing/mounting ntfs
      supportedFilesystems = [ "ntfs" ];

      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # why not ensure we can memtest workstatons easily?
        grub.memtest86.enable = true;

      };
    };

    networking.hostName = "daedalus"; # Define your hostname.
    networking.hostId = "485cafad"; # for zfs, helps stop importing to wrong machine
    networking.useDHCP = lib.mkDefault true;

    fileSystems."/" = {
      device = "rpool/local/root";
      fsType = "zfs";
      options = [ "zfsutil" ]
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/EFI";
      fsType = "vfat";
      options = [ "zfsutil" ]
    };

    fileSystems."/nix" = {
      device = "rpool/local/nix";
      fsType = "zfs";
      options = [ "zfsutil" ]
    };

    # fileSystems."/persist" =
    #   {
    #     device = "rpool/safe/persist";
    #     fsType = "zfs";
    #     neededForBoot = true; # for impermanence
    #   };

    # deaders :(
    # fileSystems."/mnt/cache" =
    #   {
    #     device = "/dev/disk/by-uuid/fe725638-ca41-4ecc-9b8a-7bf0807786e1";
    #     fsType = "xfs";
    #   };

    # TODO does this live somewhere else?
    # it is very machine-specific...
    # add user with `sudo smbpasswd -a my_user`
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "daedalus";
          "netbios name" = "daedalus";
          "security" = "user";
          "hosts allow" = "10.8.10. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
        };
        "backup" = {
          "path" = "/zfs/backup";
          "read only" = "no";
        };
        "documents" = {
          "path" = "/zfs/documents";
          "read only" = "no";
        };
        "natflix" = {
          "path" = "/tank/natflix";
          "read only" = "no";
        };
        "scans" = {
          "path" = "/zfs/documents/scans";
          "read only" = "no";
        };
        "paperless" = {
          "path" = "/zfs/documents/paperless/inbound";
          "read only" = "no";
        };
      };

    };
    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

    environment.systemPackages = with pkgs; [
      btrfs-progs
      p7zip
      unrar
    ];

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable
        {
          directories = [ "/var/lib/samba/" ];
        };

    systemd.services.org-bom-weather = {
      description = "Update and run BOM weather script";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = "org-bom-weather";
        ExecStart = [
          (pkgs.writeScript "org-bom-weather.sh" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            # Ensure SSH and git are in PATH
            export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:${pkgs.python3}/bin:$PATH"

            REPO_DIR="/var/lib/org-bom-weather"
            REPO_URL="ssh://forgejo@daedalus:2222/truxnell/org-bom-weather.git"
            OUTPUT_FILE="/zfs/syncthing/org/weather.org"

            # Clone if directory doesn't exist or is empty
            if [ ! -d "$REPO_DIR/.git" ]; then
              git clone "$REPO_URL" "$REPO_DIR"
            else
              # Force update if directory exists
              cd "$REPO_DIR"
              git fetch --force origin
              git reset --hard origin/main || git reset --hard origin/master
            fi

            # Run the Python script
            cd "$REPO_DIR"
            python3 bom_weather.py -o "$OUTPUT_FILE"
          '')
        ];
        ReadWritePaths = [
          "/var/lib/org-bom-weather"
          "/zfs/syncthing/org"
        ];
      };
    };

    systemd.timers.org-bom-weather = {
      description = "Timer for BOM weather script";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = [
          "*-*-* 05:30:00"
          "*-*-* 11:30:00"
          "*-*-* 17:30:00"
          "*-*-* 23:30:00"
        ];
        TimeZone = "Australia/Melbourne";
      };
    };

    ## Secrets
    sops.secrets."services/org-weather-observations/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = "root";
      group = "root";
      restartUnits = [ "org-weather-observations.service" ];
    };

    # sops.secrets."services/webdav/htpasswd" = {
    #   sopsFile = ./secrets.sops.yaml;
    #   owner = "nginx";
    #   group = "nginx";
    #   restartUnits = [ "nginx.service" ];
    # };

    systemd.services.org-weather-observations = let
      # Create Python environment with common dependencies
      # Add more packages here as needed
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        paho-mqtt
        # Add other dependencies here when known
      ]);
    in {
      description = "Update and run weather observations script";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = "org-weather-observations";
        EnvironmentFile = [ config.sops.secrets."services/org-weather-observations/env".path ];
        ExecStart = [
          (pkgs.writeScript "org-weather-observations.sh" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            # Ensure SSH and git are in PATH
            export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:${pythonEnv}/bin:$PATH"

            REPO_DIR="/var/lib/org-weather-observations"
            REPO_URL="ssh://forgejo@daedalus:2222/truxnell/org-weather-observations.git"
            OUTPUT_FILE="/zfs/syncthing/org/weather.org"

            # Clone if directory doesn't exist or is empty
            if [ ! -d "$REPO_DIR/.git" ]; then
              git clone "$REPO_URL" "$REPO_DIR"
            else
              # Force update if directory exists
              cd "$REPO_DIR"
              git fetch --force origin
              git reset --hard origin/main || git reset --hard origin/master
            fi


            # Run the Python script
            python3 weather_org_integration.py -o "$OUTPUT_FILE" --timeout 120
          '')
        ];
        ReadWritePaths = [
          "/var/lib/org-weather-observations"
          "/zfs/syncthing/org"
        ];
      };
    };

    systemd.timers.org-weather-observations = {
      description = "Timer for weather observations script";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/15";
      };
    };

    systemd.services.org-git-sync = {
      description = "Auto-commit and push changes in /zfs/syncthing/org/";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = [
          (pkgs.writeScript "org-git-sync.sh" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            # Ensure git and SSH are in PATH
            export PATH="${pkgs.openssh}/bin:${pkgs.git}/bin:$PATH"

            REPO_DIR="/zfs/syncthing/org"

            # Check if directory exists and is a git repository
            if [ ! -d "$REPO_DIR" ]; then
              echo "Directory $REPO_DIR does not exist, skipping"
              exit 0
            fi

            if [ ! -d "$REPO_DIR/.git" ]; then
              echo "Directory $REPO_DIR is not a git repository, skipping"
              exit 0
            fi

            cd "$REPO_DIR"

            # Check if there are any changes to commit
            if git diff --quiet && git diff --cached --quiet; then
              echo "No changes to commit"
              # Still try to push in case local is behind remote
            else
              # Add all changes
              git add -A

              # Create commit message with timestamp
              COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S %Z')"
              git commit -m "$COMMIT_MSG" || {
                echo "Commit failed (might be no changes after staging), continuing..."
              }
            fi

            # Push to remote (non-destructive, will fail if remote is ahead)
            # Use --set-upstream if needed, but don't force push
            if git remote | grep -q .; then
              git push || {
                echo "Push failed (remote might be ahead or network issue), this is non-fatal"
                exit 0
              }
            else
              echo "No remote configured, skipping push"
            fi
          '')
        ];
        ReadWritePaths = [
          "/zfs/syncthing/org"
        ];
      };
    };

    systemd.timers.org-git-sync = {
      description = "Timer for auto-committing org directory";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        RandomizedDelaySec = "5m";
      };
    };

    # WebDAV service for /zfs/syncthing/org/
    # Ensure nginx user can access the directory
    users.users.nginx.extraGroups = [ "kah" ];

    services.nginx.virtualHosts."webdav.${config.networking.domain}" = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      root = "/zfs/syncthing/org/";
      locations."/" = {
        extraConfig = ''
          dav_methods PUT DELETE MKCOL COPY MOVE;
          dav_ext_methods PROPFIND OPTIONS;
          create_full_put_path on;
          client_max_body_size 0;
        '';
      };
    };
              # auth_basic "Restricted Access";
          # auth_basic_user_file ${config.sops.secrets."services/webdav/htpasswd".path};
# 

  };
}
