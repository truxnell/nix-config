# Goals

When I set about making this lab I had a number of goals - I wonder how well I will do :thinking:?

A master list of ideas/goals/etc can be found at :octicons-issue-tracks-16: [Issue #1](https://github.com/truxnell/nix-config/issues/1)

<div class="grid cards" markdown>

- __:material-sword: Stability__ <br>NixOS stable channel for core services unstable for desktop apps/non-mission critical where desired. Containers with SHA256 pinning for server apps
- __:kiss: KISS__<br>Keep it Simple, use boring, reliable, trusted tools - not todays flashy new software repo
- __:zzz: Easy Updates__<br>Weekly update schedule, utilizing Renovate for updating lockfile and container images.  Autoupdates enabled off main branch for mission critical. Aim for 'magic rollback' on upgrade failure
- __:material-cloud-upload: Backups__<br>Nightly restic backups to both cloud and NAS. All databases to have nightly backups. _Test backups regulary_
- __:repeat: Reproducability__<br>Flakes & Git for version pinning, SHA256 tags for containers.
- __:alarm_clock: Monitoring__<br>Automated monitoring on failure & critical summaries, using basic tools. Use Gatus for both internal and external monitoring
- __:clipboard: Continuous Integration__<br>CI against main branch to ensure all code compiles OK. Use PR's to add to main and dont skip CI due to impatience
- __:material-security: Security__<br>Dont use containers with S6 overlay/root (i.e. LSIO :grey_question:{ title="LSIO trades security for convenience with their container configuration" }). Expose minimal ports at router, Reduce attack surface by keeping it simple, review hardening containers/podman/NixOS
- __:fontawesome-solid-martini-glass-citrus: Ease of administration__<br>Lean into the devil that is SystemD - and have one standard interface to see logs, manipulate services, etc. Run containers as podman services, and webui's for watching/debugging
- __:simple-letsencrypt: Secrets__ _~ssshh~.._<br>[Sops-nix](https://github.com/Mic92/sops-nix) for secrets, living in my gitrepo. Avoid cloud services like I used in k8s (i.e. [Doppler.io](https://doppler.io))
</div>
