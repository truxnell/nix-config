{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  disks = [
    {
      type = "parity";
      name = "parity0";
      uuid = "6eb8102d-8fb9-4b90-baca-d0164f167d1d"; # 20TB
    }
    {
      type = "data";
      name = "data0";
      uuid = "17d7179b-d134-463a-aeaf-5c171d6fdd28"; # 20TB
    }
    {
      type = "data";
      name = "data1";
      uuid = "dcf8c276-dd1b-4144-866d-2a24bca04488"; # 6TB
    }
    {
      type = "data";
      name = "data2";
      uuid = "b1328b55-9523-47cd-b937-5eaecaa36d6f"; # 16TB
    }
    {
      type = "data";
      name = "data3";
      uuid = "645e1ba4-14bf-42f7-84e1-c4efe7cff691"; # 16TB
    }

  ];

  parityDisks = builtins.filter (d: d.type == "parity") disks;
  dataDisks = builtins.filter (d: d.type == "data") disks;
  parityFs = builtins.listToAttrs (builtins.map
    (d: {
      name = "/mnt/${d.name}";
      value = {
        device = "/dev/disk/by-uuid/${d.uuid}";
        fsType = "xfs";
      };
    })
    parityDisks);
  dataFs = builtins.listToAttrs (builtins.concatMap
    (d: [
      {
        name = "/mnt/root/${d.name}";
        value = {
          device = "/dev/disk/by-uuid/${d.uuid}";
          fsType = "btrfs";
        };
      }
      {
        name = "/mnt/${d.name}";
        value = {
          device = "/dev/disk/by-uuid/${d.uuid}";
          fsType = "btrfs";
          options = [ "subvol=data" ];
        };
      }
      # {
      #   name = "/mnt/${d.name}/.snapshots";
      #   value = {
      #     device = "/dev/disk/by-uuid/${d.uuid}";
      #     fsType = "btrfs";
      #     options = [ "subvol=.snapshots" ];
      #   };
      # }
      {
        name = "/mnt/snapraid-content/${d.name}";
        value = {
          device = "/dev/disk/by-uuid/${d.uuid}";
          fsType = "btrfs";
          options = [ "subvol=content" ];
        };
      }
    ])
    dataDisks);
  snapraidDataDisks = builtins.listToAttrs (lib.lists.imap0
    (i: d: {
      name = "d${toString i}";
      value = "/mnt/${d.name}";
    })
    dataDisks);
  contentFiles =
    [
      "/persist/var/snapraid.content"
    ]
    ++ builtins.map (d: "/mnt/snapraid-content/${d.name}/snapraid.content") dataDisks;
  parityFiles = builtins.map (p: "/mnt/${p.name}/snapraid.parity") parityDisks;
  snapperConfigs = builtins.listToAttrs (builtins.map
    (d: {
      name = "${d.name}";
      value = {
        SUBVOLUME = "/mnt/${d.name}";
        ALLOW_GROUPS = [ "wheel" ];
        SYNC_ACL = true;
      };
    })
    dataDisks);
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    # snapraid-btrfs
    # snapraid-btrfs-runner
    xfsprogs
    btrfs-progs
  ];

  fileSystems =
    {
      "/mnt/storage" = {
        #/mnt/disk* /mnt/storage fuse.mergerfs defaults,nonempty,allow_other,use_ino,cache.files=partial,moveonenospc=true,dropcacheonclose=true,minfreespace=100G,fsname=mergerfs 0 0
        device = lib.strings.concatMapStringsSep ":" (d: "/mnt/${d.name}") dataDisks;
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "nofail"
          "nonempty"
          "allow_other"
          "use_ino"
          "cache.files=partial"
          "category.create=epmfs"
          "moveonenospc=true"
          "dropcacheonclose=true"
          "minfreespace=100G"
          "fsname=mergerfs"
          # For NFS: https://github.com/trapexit/mergerfs#can-mergerfs-mounts-be-exported-over-nfs
          "noforget"
          "inodecalc=path-hash"
          # For kodi's "fasthash" functionality: https://github.com/trapexit/mergerfs#tips--notes
          "func.getattr=newest"
        ];
      };
    }
    //
    parityFs
    // dataFs;

  services.nfs.server.exports = ''
    /mnt/storage 192.168.1.0/24(rw,sync,insecure,no_root_squash,fsid=uuid,anonuid=568,anongid=568)
  '';

  services.snapraid = {
    inherit contentFiles parityFiles;
    enable = true;
    sync.interval = "";
    scrub.interval = "";
    dataDisks = snapraidDataDisks;
    exclude = [
      "*.unrecoverable"
      "/tmp/"
      "/lost+found/"
      "downloads/"
      "appdata/"
      "*.!sync"
      "/.snapshots/"
    ];
  };

  services.snapper = {
    configs = snapperConfigs;
  };

  # services.restic.backups = config.lib.mySystem.mkRestic
  #   {
  #     app = "snapraid-content";
  #     paths = [ "/persist/var/snapraid.content" ];
  #   };



  # systemd.services.snapraid-btrfs-sync = {
  #   description = "Run the snapraid-btrfs sync with the runner";
  #   startAt = "01:00";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.snapraid-btrfs-runner}/bin/snapraid-btrfs-runner";
  #     Nice = 19;
  #     IOSchedulingPriority = 7;
  #     CPUSchedulingPolicy = "batch";

  #     LockPersonality = true;
  #     MemoryDenyWriteExecute = true;
  #     NoNewPrivileges = true;
  #     PrivateTmp = true;
  #     ProtectClock = true;
  #     ProtectControlGroups = true;
  #     ProtectHostname = true;
  #     ProtectKernelLogs = true;
  #     ProtectKernelModules = true;
  #     ProtectKernelTunables = true;
  #     RestrictAddressFamilies = "AF_UNIX";
  #     RestrictNamespaces = true;
  #     RestrictRealtime = true;
  #     RestrictSUIDSGID = true;
  #     SystemCallArchitectures = "native";
  #     SystemCallFilter = "@system-service";
  #     SystemCallErrorNumber = "EPERM";
  #     CapabilityBoundingSet = "";
  #     ProtectSystem = "strict";
  #     ProtectHome = "read-only";
  #     ReadOnlyPaths = [ "/etc/snapraid.conf" "/etc/snapper" ];
  #     ReadWritePaths =
  #       # sync requires access to directories containing content files
  #       # to remove them if they are stale
  #       let
  #         contentDirs = builtins.map builtins.dirOf contentFiles;
  #       in
  #       lib.unique (
  #         builtins.attrValues snapraidDataDisks ++ parityFiles ++ contentDirs
  #       );
  #   };
  # };
}
