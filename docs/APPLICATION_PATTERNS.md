# Application Development Patterns

This project uses two primary patterns for adding applications, with a strong preference for plain NixOS modules over containerized solutions.

## Decision Matrix: Module vs Container

| Criteria | Plain NixOS Module | OCI Container |
|----------|-------------------|---------------|
| **Official NixOS service exists** | ✅ Always prefer | ❌ Avoid |
| **Complex runtime dependencies** | ❌ May be difficult | ✅ Container handles |
| **Needs root privileges** | ✅ Proper systemd integration | ⚠️ Security concerns |
| **Frequent updates needed** | ⚠️ Requires NixOS rebuilds | ✅ Easy image updates |
| **Performance critical** | ✅ No overhead | ❌ Container overhead |
| **Custom configuration** | ✅ Full NixOS integration | ⚠️ Limited options |

## Pattern 1: Plain NixOS Modules (Preferred)

Use this pattern when official NixOS services exist or can be easily created. This provides better integration, security, and maintainability.

### When to Use
- Official NixOS service module exists
- Application has minimal runtime dependencies
- Need deep system integration
- Performance is critical
- Want declarative configuration

### Key Advantages
- **Native Integration**: Full NixOS service integration with proper systemd units
- **Security**: Proper user/group isolation and file permissions
- **Configuration**: Declarative configuration through NixOS options
- **Dependencies**: Automatic dependency resolution and service ordering
- **Performance**: No container overhead

### Boilerplate Template

```nix nixos/modules/applications/{category}/{app}/default.nix
{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "app-name";
  category = "services";  # or infrastructure, media, etc.
  description = "Brief description";
  user = app;
  group = app;
  port = 8080;  # if applicable
  appFolder = "/var/lib/${app}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };
    # Add app-specific options here
  };

  config = mkIf cfg.enable {
    ## Secrets (if needed)
    sops.secrets."${category}/${app}/env" = mkIf (builtins.pathExists ./secrets.sops.yaml) {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    ## User/Group Management
    users.users.truxnell.extraGroups = [ group ];
    users.users.${user} = {
      isSystemUser = true;
      inherit group;
    };
    users.groups.${group} = { };

    ## Persistence
    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable {
        directories = [
          {
            directory = appFolder;
            inherit user group;
            mode = "750";
          }
        ];
      };

    ## Main Service Configuration
    services.${app} = {
      enable = true;
      # Service-specific configuration
    };

    ## Database Setup (if PostgreSQL is needed)
    services.postgresql = mkIf (/* condition */) {
      ensureDatabases = [ app ];
      ensureUsers = [
        {
          name = app;
          ensureDBOwnership = true;
        }
      ];
    };

    ## Monitoring Integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    ## Reverse Proxy Configuration
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        # Add any required proxy headers
      };
    };

    ## Prometheus Metrics (if applicable)
    services.vmagent = mkIf cfg.prometheus {
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = app;
            static_configs = [
              {
                targets = [ "https://${app}.${config.mySystem.domain}/metrics" ];
              }
            ];
          }
        ];
      };
    };

    ## Backup Configuration
    warnings = [
      (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
        "WARNING: Backups for ${app} are disabled!")
    ];

    # File-based backups
    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

    # Database backups (if applicable)
    services.postgresqlBackup = mkIf (cfg.backup && /* has database */) {
      databases = [ app ];
    };
  };
}
```

### Real Example: Miniflux
See `nixos/modules/applications/productivity/miniflux/default.nix` for a complete implementation using the built-in NixOS service.

## Pattern 2: OCI Containers (Fallback)

Use this pattern when no suitable NixOS module exists or when the application requires complex runtime environments that containers handle better.

### When to Use
- No NixOS service module available
- Complex runtime dependencies (specific OS, libraries)
- Rapid iteration needed
- Application requires isolation
- Third-party image is well-maintained

### Container Security Best Practices
- **Use consistent container users**: Prefer `kah:kah` for most containers
- **Apply security constraints**: Use `--read-only`, `--cap-drop=ALL`, `--security-opt=no-new-privileges`
- **Limit network exposure**: Only expose ports externally when absolutely necessary
- **Volume security**: Mount only necessary directories with appropriate permissions

### Boilerplate Template

```nix nixos/modules/applications/{category}/{app}/default.nix
{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "app-name";
  category = "services";
  description = "Brief description";
  image = "docker.io/namespace/image:tag";
  user = "kah";  # Use consistent container user
  group = "kah";
  port = 8080;
  appFolder = "/var/lib/${app}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
      default = true;
    };
  };

  config = mkIf cfg.enable {
    ## Secrets
    sops.secrets."${category}/${app}/env" = mkIf (builtins.pathExists ./secrets.sops.yaml) {
      sopsFile = ./secrets.sops.yaml;
      owner = user;
      inherit group;
      restartUnits = [ "${app}.service" ];
    };

    ## User Management
    users.users.truxnell.extraGroups = [ group ];

    ## Persistence
    environment.persistence."${config.mySystem.system.impermanence.persistPath}" =
      lib.mkIf config.mySystem.system.impermanence.enable {
        directories = [
          {
            directory = appFolder;
            inherit user group;
            mode = "750";
          }
        ];
      };

    ## Container Configuration
    virtualisation.oci-containers.containers."${app}" = {
      inherit image;
      environment = {
        TZ = config.time.timeZone;
        # Add app-specific environment variables
      };
      environmentFiles = lib.optionals (builtins.pathExists ./secrets.sops.yaml) [
        config.sops.secrets."${category}/${app}/env".path
      ];
      volumes = [
        "${appFolder}:/app/data:rw"
        # Add additional volume mounts
      ];
      ports = lib.optionals (/* needs external access */) [
        "${builtins.toString port}:${builtins.toString port}"
      ];
      # Add security options as needed:
      # extraOptions = [
      #   "--read-only"
      #   "--security-opt=no-new-privileges"
      #   "--cap-drop=ALL"
      # ];
    };

    ## Database Setup (if needed)
    services.postgresql = mkIf (/* needs database */) {
      ensureDatabases = [ app ];
      ensureUsers = [
        {
          name = app;
          ensureDBOwnership = true;
        }
      ];
    };

    ## Monitoring Integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1500"
        ];
      }
    ];

    ## Reverse Proxy Configuration
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://${app}:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";  # Enable service discovery
      };
    };

    ## Backup Configuration
    warnings = [
      (mkIf (!cfg.backup && config.mySystem.purpose != "Development")
        "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      }
    );
  };
}
```

### Real Example: Linkding
See `nixos/modules/applications/productivity/linkding/default.nix` for a complete OCI container implementation.

## Integration Requirements

### Required Integrations
1. **Secrets Management**: Use SOPS for any sensitive configuration
2. **Monitoring**: Add Gatus health checks unless monitoring is disabled
3. **Reverse Proxy**: Configure nginx virtual host for web services
4. **Backups**: Enable appropriate backup strategy (files and/or database)
5. **Persistence**: Configure impermanence for stateful data

### Optional Integrations
- **Prometheus Metrics**: If service provides metrics endpoint
- **Homepage Integration**: For user-facing services
- **DNS Management**: For services needing custom DNS entries

## Common Patterns

### Standard Options
All services should include these standard options:
- `enable`: Main toggle for the service
- `addToHomepage`: Include in homepage dashboard
- `monitor`: Enable health monitoring
- `prometheus`: Enable metrics collection
- `addToDNS`: Add to internal DNS
- `dev`: Development instance toggle
- `backup`: Enable backup strategy

### Service Categories
- **infrastructure**: Core services (databases, message queues, etc.)
- **monitoring**: Observability and alerting tools
- **media**: Entertainment and media management
- **productivity**: Personal productivity and collaboration tools
- **networking**: Network services and utilities
- **development**: Development tools and environments
- **storage**: File storage and synchronization
- **search**: Search engines and indexing tools

### Naming Conventions
- **Module names**: Use kebab-case matching the service name
- **Variables**: Use descriptive names following existing patterns
- **URLs**: Follow `${app}.${domain}` pattern
- **Secrets**: Store in `secrets.sops.yaml` alongside module

Remember: The goal is simple, reliable, and maintainable infrastructure. Choose the pattern that best serves the core principles while providing the functionality needed.