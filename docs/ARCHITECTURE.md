# Repository Architecture

This document outlines the structure and organization of the NixOS homelab configuration repository.

## Core Structure

```
├── flake.nix              # Main flake definition with inputs/outputs
├── nixos/
│   ├── global.nix         # Global configuration applied to all hosts
│   ├── lib/               # Custom library functions
│   ├── modules/           # Modular service definitions
│   │   ├── applications/  # Service modules by category
│   │   └── nixos/        # System-level modules
│   ├── hosts/            # Host-specific configurations
│   └── overlays/         # Package overlays
├── Justfile              # Task automation
├── deployments/          # Deployment configurations
└── docs/                 # Documentation
```

## Module Organization

### Applications Directory Structure
```
applications/
├── {category}/           # Group by function
│   ├── default.nix      # Category-wide imports
│   └── {app}/
│       ├── default.nix  # Main module
│       └── secrets.sops.yaml  # Encrypted secrets (if needed)
```

### Module Categories
- **applications/**: User-facing services organized by function
  - **infrastructure/**: Core services (databases, message queues, etc.)
  - **monitoring/**: Observability and alerting tools
  - **media/**: Entertainment and media management
  - **productivity/**: Personal productivity and collaboration tools
  - **networking/**: Network services and utilities
  - **development/**: Development tools and environments
  - **storage/**: File storage and synchronization
  - **search/**: Search engines and indexing tools

- **nixos/**: System-level configuration modules
  - **system/**: Core system configuration
  - **services/**: System services and daemons
  - **security/**: Security configuration (ACME, etc.)
  - **programs/**: System programs and shells
  - **editor/**: Editor configurations

### Host Organization
```
hosts/
├── {hostname}/
│   ├── default.nix      # Main host configuration
│   ├── hardware.nix     # Hardware-specific configuration
│   └── services.nix     # Enabled services for this host
```

## Custom Library (nixos/lib/)

### Key Functions
- `mkService`: Main service builder with container/security options
- `mkTraefikLabels`: Standardized reverse proxy configuration
- `mkRestic`: Backup configuration helper
- `existsOrDefault`: Safe attribute access with fallbacks
- `firstOrDefault`: Helper for default value resolution

### Service Module Pattern
```nix
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add to homepage" // { default = true; };
    monitor = mkOption { 
      type = lib.types.bool; 
      description = "Enable gatus monitoring"; 
      default = true; 
    };
    # ... other standard options
  };

  config = mkIf cfg.enable {
    # Service implementation
  };
}
```

## Configuration Layers

### 1. Global Configuration (`nixos/global.nix`)
Applied to all hosts, includes:
- Base system packages
- Common services (SSH, monitoring agents)
- Security baseline
- User accounts

### 2. Host-Specific Configuration
- Hardware configuration
- Host-specific services
- Network configuration
- Storage configuration

### 3. Service Modules
- Individual application configuration
- Service-specific secrets
- Integration with monitoring/backup systems

## Flake Structure

### Inputs
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
  
  # Security
  sops-nix.url = "github:mic92/sops-nix";
  
  # Deployment
  deploy-rs.url = "github:serokell/deploy-rs";
  
  # System management
  impermanence.url = "github:nix-community/impermanence";
  
  # Additional inputs...
};
```

### Outputs
- `nixosConfigurations`: Host system configurations
- `deploy`: Deployment configurations via deploy-rs
- `devShells`: Development environments
- `packages`: Custom packages and scripts

## Secret Management

### SOPS Integration
- Secrets stored in `secrets.sops.yaml` files alongside modules
- Age encryption using SSH keys
- Automatic secret injection into services
- Per-service secret isolation

### Secret Organization
```
secrets.sops.yaml structure:
services:
  app-name:
    env: |
      SECRET_KEY=value
      API_TOKEN=value
```

## Persistence Strategy

### Impermanence
- System state is ephemeral by default
- Important data persisted in `/persist`
- Configuration declares what to persist
- Clean system state on every boot

### ZFS Integration
- Important data on ZFS datasets
- Automatic snapshots and replication
- Separate datasets for different data types

## Network Architecture

### Internal Networking
- Domain: `.l.voltaicforge.com`
- Internal DNS resolution
- Service discovery via nginx reverse proxy
- Container networking with bridge

### Service Exposure
- All services behind nginx reverse proxy
- ACME certificates for HTTPS
- Internal-only access by default
- Explicit external exposure when needed

## Monitoring and Observability

### Integrated Monitoring
- Gatus for service health checks
- VictoriaMetrics for metrics collection
- Grafana for visualization
- Automatic service discovery

### Backup Strategy
- Restic for file-based backups
- PostgreSQL dump backups
- Backblaze B2 remote storage
- Automated backup verification

## Development Workflow

### Local Development
- Nix development shells
- Local testing with `just test`
- Flake validation with `nix flake check`

### Remote Deployment
- deploy-rs for atomic deployments
- SSH-based remote builds
- Rollback capability
- Pre-deployment validation

## Anti-Patterns to Avoid

### ❌ Poor Practices
- Hardcoded secrets or configuration
- Complex nested conditionals
- Overuse of containers when NixOS modules exist
- Mixing concerns across module boundaries
- Manual configuration drift

### ✅ Preferred Patterns
- Modular service definitions with clear options
- SOPS secrets co-located with service modules
- Consistent naming: `${category}/${app}` format
- Built-in NixOS modules when available and reliable
- Declarative configuration throughout

## Future Considerations

### Scalability
- Module system can handle dozens of services
- Host configurations scale to multiple machines
- Secrets management scales with proper organization

### Maintainability
- Clear separation of concerns
- Self-documenting configuration
- Consistent patterns across all modules
- Automated testing and validation

This architecture prioritizes simplicity, reliability, and maintainability while providing the flexibility to grow and adapt to changing requirements.