# Claude Configuration for NixOS Homelab Repository

This file provides essential context for AI assistants working with this NixOS homelab configuration repository.

## Critical Methodology & Goals
- **Primary Goal**: Simple, reliable, and robust homelab infrastructure
- **Dependency Philosophy**: Avoid dependencies unless benefits outweigh maintenance burden
- **Technology Preference**: Plain Nix/NixOS modules > OCI containers > complex tooling
- **Stability**: Use stable channel for production hosts, unstable only when features justify it

## Quick Reference
- **Application Development**: See [docs/APPLICATION_PATTERNS.md](docs/APPLICATION_PATTERNS.md)
- **Repository Structure**: See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Development Workflow**: See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

## Key Files to Understand
- `flake.nix`: Input management, system definitions
- `nixos/global.nix`: Baseline configuration for all hosts
- `nixos/lib/default.nix`: Custom helper functions
- `Justfile`: Operational task definitions

## Environment Context
- **Development**: Nix dev-container environment (no direct host access)
- **Deployment**: Remote hosts via SSH (daedalus, shodan)
- **Storage**: ZFS for important data, impermanence for system state
- **Networking**: Internal domain `.l.voltaicforge.com` for services

When making changes, always consider the impact on system reliability and maintainability.
