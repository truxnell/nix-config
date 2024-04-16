# Features

Some things I'm proud of. Or just happy they exist so I can forget about something until I need to worry.

<div class="grid cards" markdown>
- :octicons-copy-16: [__Nightly Backups__](/maintenance/backups/)<br>A ZFS snapshot is done at night, with restic then backing up to both locally and cloud.  NixOS wrappers make restoring a single command line entry.<br><br>ZFS snapshot before backup is important to ensure restic isnt backing up files that are in use, which would cause corruption.
- :material-update: [__Software Updates__](/maintenance/software_updates/)<br>Renovate Bot regulary runs on this Github repo, updating the flake lockfile, containers and other dependencies automatically.<br><br> Automerge is enabled for updates I expect will be routine, but waits for manual PR approval for updates I suspect may require reading changelog for breaking changes
- :ghost: __Impermance__:<br>Inspried by the [Erase your Darlings](https://grahamc.com/blog/erase-your-darlings/) post, Servers run zfs and rollback to a blank snapshot at night.  This ensures repeatable NixOS deployments and no cruft, and also hardens servers a little.
- :material-alarm-light: __SystemD Notifications__:<br>Systemd hook that adds a pushover notification to __any__ systemd unit failure for any unit NixOS is aware of.  No worrying about forgetting to add a notification to every new service or worrying about missing one.
</div>
