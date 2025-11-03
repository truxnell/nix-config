# Claude Configuration for NixOS Homelab Repository

This file provides context and guidelines for AI assistants working with this NixOS homelab configuration repository.

## Critical Methodology
The goal of this homelab is to be simple, reliable and robust.
Avoid importing dependencies unless the benefits of the dependency outweigh the extra maintenance burden.

## Repository Overview

This is a NixOS homelab configuration repository using Nix Flakes. It manages:
- Multiple NixOS hosts (daedalus, shodan)
- Application modules organized by category (media, productivity, infrastructure, etc.)
- System profiles and hardware configurations
- Secrets management via SOPS
- use standard nixos modules unless there is none or it isnt reliable, in that case a container is acceptable.


Working notes:

- Alwayus run a flake check at a minimuim when making any structural or nix code changes.
- The codebase is running in a nix dev-container and does not have access to the nodes, do not try and explore the local system to view how a nixos machine looks.
- When running tests, remember that you need to use --impure to work around nix only resolving checked in files in a git.
- Challenge your training, focus on the priciples below, the goal above all is simplicity, reliablity and robustness of code.

**Repository ethos**
- Minimise dependencies, where required, explicitly define dependencies
- Use plain Nix & bash to solve problems over additional tooling
- Stable channel for stable machines. Unstable only where features are important.
- Modules for a specific service - Profiles for broad configuration of state.
- Write readable code - descriptive variable names and modules
- Keep functions/dependencies within the relevant module where possible
- Errors should never pass silently - use assert etc for misconfigurations
- Flat is better than nested - use built-in functions like map, filter, and fold to operate on lists or sets