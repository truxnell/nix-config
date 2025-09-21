# NixOS homelab task runner – deploy-rs edition
# Usage: just <task>

flake := "."
hosts  := "daedalus shodan"

# Default task
default:
    @just --list

# Format all Nix files
fmt:
    nix fmt

# Build the system profile for a given host
build host:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel

# Dry-run deploy (activate script is run with --dry-activate)
dry-deploy host:
    nix run .#deploy -- --dry-activate --skip-checks {{host}}

# Deploy a single host with deploy-rs
deploy host:
    nix run .#deploy -- {{host}}

# Deploy all defined hosts
deploy-all:
    nix run .#deploy

# Garbage collect old generations
gc:
    sudo nix-collect-garbage -d

# Update flake inputs
update:
    nix flake update

# Run nix flake check
check:
    nix flake check
