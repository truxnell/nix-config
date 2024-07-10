{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  ## Formatting disks
  # sudo parted /dev/sdk mklabel gpt
  # sudo parted -a opt /dev/sdk mkpart primary btrfs 0% 100%
  # sudo mkfs.btrfs /dev/sdh1
  ## Mount drives temporarily
  # create data, content and .snapshot folders
  # sudo btrfs subvol create /mnt/tmp/data
  # sudo btrfs subvol create /mnt/tmp/content
  # sudo btrfs subvol create /mnt/tmp/.snapshots

  disks = [
    {
      type = "parity";
      name = "parity0";
      # 20TB wwn-0x5000c500e65322f6
      uuid = "6eb8102d-8fb9-4b90-baca-d0164f167d1d";
    }
    {
      type = "data";
      name = "data0";
      # 20TB wwn-0x5000c500e64e4a57
      uuid = "17d7179b-d134-463a-aeaf-5c171d6fdd28";
    }
    {
      type = "data";
      name = "data1";
      # 6TB wwn-0x50014ee2b6a93916
      uuid = "dcf8c276-dd1b-4144-866d-2a24bca04488";
    }
    {
      type = "data";
      name = "data2";
      # 18TB wwn-0x5000cca2a6c067ab
      uuid = "b1328b55-9523-47cd-b937-5eaecaa36d6f";
    }
    {
      type = "data";
      name = "data3";
      # 18TB wwn-0x5000cca2a6c0631a
      uuid = "645e1ba4-14bf-42f7-84e1-c4efe7cff691";
    }
    {
      type = "data";
      name = "data4";
      # 18TB wwn-0x5000cca2b4c7693b
      uuid = "e29760af-5c0d-4c53-9f32-aaaf3034c7a8";
    }
    {
      type = "data";
      name = "data5";
      # 18TB wwn-0x5000cca2cfc0a510
      uuid = "2d642e37-20a5-4f97-8392-8471f9e17901";
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
          options = [ "compress=zstd,subvol=data" ];
        };
      }
      {
        name = "/mnt/${d.name}/.snapshots";
        value = {
          device = "/dev/disk/by-uuid/${d.uuid}";
          fsType = "btrfs";
          options = [ "compress=zstd,subvol=.snapshots" ];
        };
      }
      {
        name = "/mnt/snapraid-content/${d.name}";
        value = {
          device = "/dev/disk/by-uuid/${d.uuid}";
          fsType = "btrfs";
          options = [ "compress=zstd,subvol=content" ];
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
    fuse3
    mergerfs
    snapraid-btrfs
    snapraid-btrfs-runner
    xfsprogs
    btrfs-progs
  ];

  # format drive btrfs (parity xfs)
  # btrfs subvol create data/content/.snapshots
  # 

  systemd.tmpfiles.rules = [
    "f /persist/var/snapraid.content 0750 truxnell users -" #The - disables automatic cleanup, so the file wont be removed after a period
    "f /persist/var/snapraid.content.lock 0750 truxnell users -" #The - disables automatic cleanup, so the file wont be removed after a period
  ];


  fileSystems =
    {
      "/tank" = {
        #/mnt/disk* /mnt/storage fuse.mergerfs defaults,nonempty,allow_other,use_ino,cache.files=partial,moveonenospc=true,dropcacheonclose=true,minfreespace=100G,fsname=mergerfs 0 0
        device = lib.strings.concatMapStringsSep ":" (d: "/mnt/${d.name}") dataDisks
        + ":/zfs";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "nofail" # I believe this needs fuse3
          "nonempty"
          "allow_other"
          "use_ino"
          "cache.files=partial"
          "category.create=mfs"
          "moveonenospc=true"
          "dropcacheonclose=true"
          "minfreespace=100G"
          "fsname=mergerfs"
          "ignorepponrename=true" # Helps hardlinking
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

  # nfs
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /tank 10.8.10.1/24(no_subtree_check,all_squash,anonuid=568,anongid=568,rw,fsid=0) 10.8.20.1/24(no_subtree_check,all_squash,anonuid=568,anongid=100,rw,fsid=0)
  '';
  # disable v2/v3 nfs to force v4
  services.nfs.settings.nfsd = {
    # UDP="off";
    # rdma = "true"; # Remote Direct Memory Access
    vers3 = "false";
    vers4 = "true";
    "vers4.0" = "false";
    "vers4.1" = "false";
    "vers4.2" = "true";
  };
  networking.firewall.allowedTCPPorts = [ 2049 20048 111 ];


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



  systemd.services.snapraid-btrfs-sync = {
    description = "Run the snapraid-btrfs sync with the runner";
    startAt = "01:00";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.snapraid-btrfs-runner}/bin/snapraid-btrfs-runner";
      Nice = 19;
      IOSchedulingPriority = 7;
      CPUSchedulingPolicy = "batch";

      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = "AF_UNIX";
      RestrictNamespaces = true;
      # RestrictRealtime = true;
      # RestrictSUIDSGID = true;
      # SystemCallArchitectures = "native";
      # SystemCallFilter = "@system-service";
      # SystemCallErrorNumber = "EPERM";
      # CapabilityBoundingSet = "";
      # ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadOnlyPaths = [ "/etc/snapraid.conf" "/etc/snapper" ];
      ReadWritePaths =
        # sync requires access to directories containing content files
        # to remove them if they are stale
        let
          contentDirs = builtins.map builtins.dirOf contentFiles;
        in
        lib.unique (
          builtins.attrValues snapraidDataDisks ++ parityFiles ++ contentDirs
        );
    };
  };
}
