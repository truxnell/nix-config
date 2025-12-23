# NixOS homelab task runner – deploy-rs edition
# Usage: just <task>

flake := "."
hosts  := "daedalus shodan"

# Default task
default:
    @just --list

# Formatting & Linting
# Format all Nix files
fmt:
    nix fmt

# Run statix lint
lint:
    statix check .

# Run lint and pre-commit checks
check:
    just lint
    just pre-commit-run

# Run comprehensive test suite
test-all:
    ./test-flake.sh

# Validate OCI container images from NixOS configurations
validate-images:
    #!/usr/bin/env bash
    nix-shell -p skopeo jq --run './scripts/validate-oci-images.sh'

# Local NixOS Operations
# Build the system profile for a given host
build host:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel
    nvd diff /run/current-system result

# Test build without applying (creates new generation but doesn't activate)
test host:
    sudo nixos-rebuild test --flake {{flake}}#{{host}} --impure

# Dry-activate: show what would change without applying (useful for refactoring)
dry-activate host:
    sudo nixos-rebuild dry-activate --flake {{flake}}#{{host}} --impure

# Switch configuration locally (alternative to deploy-rs)
switch host:
    sudo nixos-rebuild switch --flake {{flake}}#{{host}} --impure

# Debug switch with verbose output and trace (useful for troubleshooting)
switch-debug host:
    sudo nixos-rebuild switch --flake {{flake}}#{{host}} --impure --show-trace --verbose

# Remote Deployment (deploy-rs)
# Dry-run deploy (activate script is run with --dry-activate)
dry-deploy host:
    deploy .#{{host}} --dry-activate --remote-build --skip-checks

# Deploy a single host with deploy-rs
deploy host:
    deploy .#{{host}} --remote-build
# Deploy a single host with deploy-rs
deploy-force host:
    deploy .#{{host}} --remote-build --auto-rollback false

# Deploy all defined hosts
deploy-all:
    deploy . --remote-build 

# Restic Backup Justfile Deployment
# Deploy restic backup Justfiles to all nodes
deploy-backup-justfiles:
    deploy . --remote-build

# Deploy restic backup Justfile to a specific host
deploy-backup-justfile host:
    deploy .#{{host}} --remote-build

# Maintenance
# Garbage collect old generations
gc:
    sudo nix-collect-garbage -d

# Update flake inputs
update:
    nix flake update

# Update specific flake input (usage: just update-input i=home-manager)
update-input i:
    nix flake update {{i}}

# Show system generation history
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Remove all generations older than specified days (usage: just clean days=7)
clean days="7":
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than {{days}}d

# Run nix flake check
flake-check:
    nix flake check

# Development & Exploration
# Open nix REPL with nixpkgs
repl:
    nix repl -f flake:nixpkgs

# SOPS Secrets Management
# Re-encrypt all SOPS secrets
sops-reencrypt:
    #!/usr/bin/env bash
    find . -type f -name '*.sops.yaml' ! -name ".sops.yaml" | while read file; do
        echo "Re-encrypting $file"
        sops --decrypt --in-place "$file"
        sops --encrypt --in-place "$file"
    done

# Pre-commit
# Initialize pre-commit hooks
pre-commit-init:
    pre-commit install --install-hooks

# Update pre-commit dependencies
pre-commit-update:
    pre-commit autoupdate

# Run pre-commit on all files
pre-commit-run:
    pre-commit run --all-files

# Container lifecycle management
dev-start:
    podman run -d --rm \
        -v /mnt/nas/backup/nix-config/:/workspace:Z \
        -u 1000:1000 \
        -p 2222:22 \
        ghcr.io/xtruder/nix-devcontainer



