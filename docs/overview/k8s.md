Removed complexity

- external secrets -> bog standard sops
- HA file storage -> standard file system
- HA database cluster -> nixos standard cluster
- Database user operator -> nixos standard ensure_users
- Database permissions operator -> why even??
- secrets reloader -> sops restart_unit
- easier managment, all services run through systemd for consistency, cockpit makes viewing logs/pod console etc easy.
