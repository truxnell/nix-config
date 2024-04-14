Nightly Backups are facilitated by nixos restic module & a helper module ive written.

These run to my NAS 'local' and cloudflare R2 'remote'

They are a systemd timer/service so you can query or trigger a manual run with

```bash
truxnell@daedalus ~> systemctl status restic-backups-lidarr-local.timer
● restic-backups-lidarr-local.timer
     Loaded: loaded (/etc/systemd/system/restic-backups-lidarr-local.timer; enabled; preset: enabled)
     Active: active (waiting) since Sat 2024-04-13 19:50:23 AEST; 12h ago
    Trigger: Mon 2024-04-15 03:03:22 AEST; 18h left
   Triggers: ● restic-backups-lidarr-local.service

truxnell@daedalus ~> systemctl status restic-backups-lidarr-local.service
○ restic-backups-lidarr-local.service
     Loaded: loaded (/etc/systemd/system/restic-backups-lidarr-local.service; linked; preset: enabled)
     Active: inactive (dead) since Sun 2024-04-14 04:20:02 AEST; 4h 14min ago
TriggeredBy: ● restic-backups-lidarr-local.timer
    Process: 774197 ExecStartPre=/nix/store/vw03a7pxjj1sf59rk1p65nbv1jjwba1b-unit-script-restic-backups-lidarr-local-pre-start/bin/restic-backups-lidarr-local-pre-start (code=exited, status=0/SUCCESS)
    Process: 774210 ExecStart=/nix/store/cbg69gn45canlna2fsy7y9g72kv5q9y3-restic-0.16.4/bin/restic backup --exclude-file=/nix/store/bk1cxh78aaxbnh22jcxw18jadhk7j2b7-exclude-patterns --files-from=/run/restic-backups-lidarr-local/includes >
    Process: 774239 ExecStart=/nix/store/cbg69gn45canlna2fsy7y9g72kv5q9y3-restic-0.16.4/bin/restic forget --prune --keep-daily 7 --keep-weekly 5 --keep-monthly 12 (code=exited, status=0/SUCCESS)
    Process: 774251 ExecStart=/nix/store/cbg69gn45canlna2fsy7y9g72kv5q9y3-restic-0.16.4/bin/restic check (code=exited, status=0/SUCCESS)
    Process: 774381 ExecStopPost=/nix/store/nk9a304p38yxfgb6f63s6nq1c4icjplb-unit-script-restic-backups-lidarr-local-post-stop/bin/restic-backups-lidarr-local-post-stop (code=exited, status=0/SUCCESS)
   Main PID: 774251 (code=exited, status=0/SUCCESS)
         IP: 0B in, 0B out
        CPU: 21.961s

```

Checking snapshots

```bash
truxnell@daedalus ~ [3]> sudo restic-lidarr-local snapshots
repository a2847581 opened (version 2, compression level auto)
ID        Time                 Host        Tags        Paths
----------------------------------------------------------------------------
aef44e7c  2024-04-13 19:56:14  daedalus                /persist/nixos/lidarr
b96f4b94  2024-04-14 04:19:41  daedalus                /persist/nixos/lidarr
----------------------------------------------------------------------------
```

Testing a restore (would do --target / for a real restore)
Would just have to pause service, run restore, then re-start service.

```bash
truxnell@daedalus ~ [1]> sudo restic-lidarr-local restore --target /tmp/lidarr/ latest
repository a2847581 opened (version 2, compression level auto)
[0:00] 100.00%  2 / 2 index files loaded
restoring <Snapshot b96f4b94 of [/persist/nixos/lidarr] at 2024-04-14 04:19:41.533770692 +1000 AEST by root@daedalus> to /tmp/lidarr/
Summary: Restored 52581 files/dirs (11.025 GiB) in 1:37
```
