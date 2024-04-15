# Goals

When I set about making this lab I had a number of goals - I wonder how well I will do?

| Goal | How |
|---|--|
| Stability | NixOS stable channel |

* stable channel for reliable services, with unstable for desktop apps, * containers for 'server' apps
* renovate for automated lockfile and container updates
* strong CI on all PR's to ensure system updates from main branch are reliable
* leans into systemd, meaning everything can be managed, viewed and debugged with a consistent interface (Ive come around to loving systemd...)
* cockpit on all servers for easy viewing of status logs, etc
* sops-nix for secrets
* nightly restic backups (diff) to local and cloud, with failure notifications and simple command-line wrapper for restores
* gatus monitoring for apps, dns and servers, dynamicaly built from nix across all enabled nodes
*
