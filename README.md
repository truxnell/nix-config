# Truxnell's homelab

[![NixOS](https://img.shields.io/badge/NIXOS-5277C3.svg?style=for-the-badge&logo=NixOS&logoColor=white)](https://nixos.org)
[![NixOS](https://img.shields.io/badge/NixOS-23.11-blue?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![MIT License](https://img.shields.io/github/license/truxnell/nix-config?style=for-the-badge)](https://github.com/truxnell/nix-config/blob/ci/LICENSE)

[![renovate](https://img.shields.io/badge/renovate-enabled-%231A1F6C?logo=renovatebot)](https://developer.mend.io/github/truxnell/nix-config)
[![Flake Lock Update](https://github.com/truxnell/nix-config/actions/workflows/update-flake.yaml/badge.svg)](https://github.com/truxnell/nix-config/actions/workflows/update-flake.yaml)
![Code Comprehension](https://img.shields.io/badge/Code%20comprehension-26%25-red)

Leveraging nix, nix-os and other funny magic man words to apply machine and home configurations

[Repository Documentation](https://truxnell.github.io/nix-config/)

## Background

Having used a variety of infracture as code solutions - and having found them lacking in some areas, it is time to give nix a go.
Frustrations with other methods tend to be bitrot and config drift - very annoying to want to do a quick disaster recovery and find your have different versions of modules/utilities, breaking changes in code you didnt catch, etc.

## Getting started

To Install

```
# nixos-rebuild switch --flake github:truxnell/nix-config#HOST
```

## Goals

### Completed
- [X] Learn nix
- [X] Mostly reproduce features from my existing homelab
- [X] Replace existing ubuntu-based 'NAS'
- [X] Handle secrets - decided on SOPS for simplicity
- [X] Keep it simple, use trusted boring tools
- [X] Establish code quality infrastructure (formatting, linting, pre-commit)

### Active Focus
- [ ] Expand usage to other shell environments such as WSL, etc
- [ ] Comprehensive testing infrastructure
- [ ] Enhanced CI/CD workflows
- [ ] Developer experience improvements

### Future
- [ ] Additional hosts (NUC, RasPi)
- [ ] VM build configurations
- [ ] Expanded monitoring and observability

## TODO

- [X] Github Actions update fly.io instances (Bitwarden)
- [ ] Bring over hosts (landed on bazzite for laptop/gaming desktop)
  - [x] NAS
  - [ ] NUC
  - [ ] JJY raspi
- [x] Documentation!
- [x] ssh_config build from computers?
- [x] Modularise host to allow vm builds and hw builds
- [x] Add license
- [x] Add taskfiles

## Checklist

### Adding new node

- Ensure secrets are grabbed from note and all sops re-encrypte with task sops:re-encrypt
- Add to relevant github action workflows
- Add to .github/settings.yaml for PR checks

## Applying configuration changes on a local machine can be done as follows:

```sh
cd ~/dotfiles
sudo nixos-rebuild switch --flake .
# This will automatically pick the configuration name based on the hostname
```

Applying configuration changes to a remote machine can be done as follows:

```sh
cd ~/dotfiles
nixos-rebuild switch --flake .#nameOfMachine --target-host machineToSshInto --use-remote-sudo
```

## Developer Workflow

### Code Quality

Before committing changes:

```bash
# Format code
just fmt

# Run linting
just lint

# Run comprehensive checks (lint + pre-commit)
just check

# Run full test suite
just test-all
```

### Pre-Commit Setup

Install pre-commit hooks for automatic checks:

```bash
just pre-commit-init
```

This will run formatting, linting, and security checks automatically on commit.

### Testing

Run validation tests:

```bash
# Quick validation
nix flake check --no-build

# Comprehensive test suite
./test-flake.sh

# Test specific host configuration
nix eval --impure .#nixosConfigurations.daedalus.config.system.name
```

See [Testing Guide](docs/development/testing.md) for more details.

## Hacking at nix files

Eval config to see what keys are being set.

```bash
nix eval .#nixosConfigurations.rickenbacker.config.security.sudo.WheelNeedsPassword
nix eval .#nixosConfigurations.rickenbacker.config.mySystem.security.wheelNeedsPassword
```

And browsing whats at a certain level in options - or just use [nix-inspect](https://github.com/bluskript/nix-inspect) TUI 

```bash
nix eval .#nixosConfigurations.rickenbacker.config.home-manager.users.truxnell --apply builtins.attrNames --json
```

Quickly run a flake to see what the next error message is as you hack.

```bash
nixos-rebuild dry-run --flake . --fast --impure
```

## Links & References

- [Misterio77/nix-starter-config](https://github.com/Misterio77/nix-starter-configs)
- [billimek/dotfiles](https://github.com/billimek/dotfiles/)
- [Erase your Darlings](https://grahamc.com/blog/erase-your-darlings/)
- [NixOS Flakes](https://www.tweag.io/blog/2020-07-31-nixos-flakes/)
