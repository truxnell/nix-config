# Truxnell's homelab

[![NixOS](https://img.shields.io/badge/NixOS-23.11-blue?style=flat&logo=nixos&logoColor=white)](https://nixos.org)
Leveraging nix, nix-os to apply machine and home configurations

## Background

Having used a variety of infracture as code solutions - and having found them lacking in some areas, it is time to give nix a go.
Frustrations with other methods tend to be bitrot and config drift - very annoying to want to do a quick disaster recovery and find your have different versions of modules/utilities, breaking changes in code you didnt catch, etc.

## Getting started

To Install

```
# nixos-rebuild switch --flake github:truxnell/nix-config#HOST
```

## Goals

- [ ] Learn nix
- [ ] Mostly reproduce features from my existing homelab
- [ ] Replace existing ubuntu-based 'NAS'
- [ ] Expand usage to other shell environments such as WSL, etc
- [ ] handle secrets - decide between sweet and simple SOPS or re-use my doppler setup.

## TODO

- [ ] Github Actions update fly.io instances (Bitwarden)
- [ ] Bring over hosts
  - [ ] DNS01 Raspi4
  - [ ] DNS02 Raspi4
  - [ ] NAS
  - [ ] Latop
  - [ ] WSL
  - [ ] JJY emulator Raspi4
- [ ] Documentation!
- [ ] ssh_config build from computers?
- [ ] Modularise host to allow vm builds and hw builds
- [ ] Add license
- [ ] Add taskfiles

## Network map

TBC

## Hardware

TBC

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

## Hacking at nix files

Eval config to see what keys are being set.

```bash
nix eval .#nixosConfigurations.rickenbacker.config.security.sudo.WheelNeedsPassword
nix eval .#nixosConfigurations.rickenbacker.config.mySystem.security.wheelNeedsPassword
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
