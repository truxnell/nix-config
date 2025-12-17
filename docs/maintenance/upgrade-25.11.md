## NixOS 25.11 upgrade

This document describes how to upgrade this flake and all hosts to NixOS 25.11.

### 1. Update flake inputs and lock file

- Ensure `flake.nix` points `nixpkgs` at the 25.11 channel (already done in this repo).
- On your development machine, from the repo root, run:

```bash
nix flake update
```

This will refresh `flake.lock` to match the 25.11 inputs.

### 2. Run flake checks

From the repo root:

```bash
./test-flake.sh
```

This script runs:

- `nix-instantiate --parse flake.nix`
- `nix flake metadata` and `nix flake show`
- `nix flake check --no-build`
- Evaluation of all `nixosConfigurations`
- Basic validation of `lib` and application imports

Fix any reported issues before proceeding.

### 3. Per-host system builds

For each host defined under `nixosConfigurations`:

```bash
nix build .#nixosConfigurations.daedalus.config.system.build.toplevel
nix build .#nixosConfigurations.shodan.config.system.build.toplevel
nix build .#nixosConfigurations.xerxes.config.system.build.toplevel
```

Only proceed once all hosts build successfully.

### 4. Canary host upgrade

Pick a canary host (for example `daedalus`) and, on that host, run:

```bash
sudo nixos-rebuild test --flake /path/to/this/repo#daedalus
```

If everything looks good (services start, no obvious regressions), commit the change with:

```bash
sudo nixos-rebuild switch --flake /path/to/this/repo#daedalus
```

Reboot the canary and verify:

- Networking and storage
- Core services (e.g. monitoring, backups)
- Any important applications (e.g. gaming stack like Factorio)

Confirm that the bootloader still exposes older generations for rollback.

### 5. Rollout to remaining hosts

For each remaining host (e.g. `shodan`, `xerxes`):

```bash
sudo nixos-rebuild test --flake /path/to/this/repo#shodan
sudo nixos-rebuild switch --flake /path/to/this/repo#shodan

sudo nixos-rebuild test --flake /path/to/this/repo#xerxes
sudo nixos-rebuild switch --flake /path/to/this/repo#xerxes
```

Upgrade hosts in batches according to how critical they are, validating services after each batch.

### 6. Post-upgrade cleanup

- Remove any temporary workarounds you added while debugging 25.11 issues.
- Consider adopting new NixOS 25.11 options or modules where they simplify your config.
- Keep `./test-flake.sh` as a quick regression check for future flake or NixOS upgrades.


