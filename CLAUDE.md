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

## Repository Structure

```
nixos/
├── hosts/              # Host-specific configurations
│   ├── daedalus/       # NAS server
│   └── shodan/         # Homelab server
├── modules/
│   ├── applications/   # Application modules (organized by category)
│   │   ├── media/      # Media services (jellyfin, plex, sonarr, etc.)
│   │   ├── productivity/ # Productivity apps (miniflux, paperless, etc.)
│   │   ├── infrastructure/ # Infrastructure (nginx, postgresql, podman, etc.)
│   │   ├── monitoring/ # Monitoring tools (grafana, gatus, etc.)
│   │   ├── networking/ # Networking services (traefik, mosquitto, etc.)
│   │   ├── storage/    # Storage services (seafile, syncthing)
│   │   ├── gaming/     # Gaming servers
│   │   ├── search/     # Search engines (whoogle, searxng)
│   │   ├── development/ # Development tools
│   │   ├── misc/       # Miscellaneous applications
│   │   └── _archive/   # Unused/archived applications
│   └── nixos/          # Core NixOS modules
│       ├── services/   # Service module import registry (default.nix + special files)
│       └── containers/ # Container module import registry (default.nix only)
├── global.nix          # Base system configuration (includes global, server, and dev roles)
├── global-secrets.sops.yaml # Global SOPS secrets
├── lib/                # Custom library functions
└── overlays/           # Nix package overlays

flake.nix               # Main flake definition
```

## When to Run Tests

### Automatic Test Execution

Remember to run test as impure or run `git add .` on changes, nix only runs tracket files in a git.

**Always run `nix flake check` when:**
- Modifying `flake.nix`
- Adding or removing NixOS configurations
- Changing module structure or imports in `nixos/modules/nixos/services/default.nix` or `nixos/modules/nixos/containers/default.nix`
- Modifying flake outputs (lib, formatter, etc.)
- Any change that affects the flake's evaluated structure

**Run fast validation tests when:**
- Adding or modifying application modules
- Changing host configurations
- Modifying library functions in `nixos/lib/`

### Manual Test Execution

After making changes, run tests in this order:

1. **Quick syntax check:**
   ```bash
   nix-instantiate --parse flake.nix > /dev/null
   ```

2. **Fast flake validation:**
   ```bash
   nix flake check --no-build
   ```

3. **Full flake check (may take longer):**
   ```bash
   nix flake check
   ```

4. **Configuration evaluation (test specific hosts):**
   ```bash
   nix eval .#nixosConfigurations.daedalus.config.system.name
   nix eval .#nixosConfigurations.shodan.config.system.name
   ```

5. **Test script (comprehensive validation):**
   ```bash
   ./test-flake.sh
   ```

6. **Flake output validation:**
   ```bash
   # Validate hosts
   nix eval --impure .#nixosConfigurations --apply 'x: builtins.attrNames x'
   # Validate formatter
   nix eval --impure .#formatter --apply 'x: builtins.hasAttr "x86_64-linux" x'
   ```

## Fast Tests Documentation

### 1. Flake Syntax Check
**Command:** `nix-instantiate --parse flake.nix > /dev/null`  
**When:** Before any other test, catches syntax errors quickly  
**Duration:** < 1 second

### 2. Flake Metadata Check
**Command:** `nix flake metadata --no-write-lock-file`  
**When:** After syntax check, validates flake structure  
**Duration:** 2-5 seconds

### 3. Flake Show (List Outputs)
**Command:** `nix flake show --no-write-lock-file`  
**When:** After metadata check, verifies all outputs are accessible  
**Duration:** 2-5 seconds

### 4. Flake Check (No Build)
**Command:** `nix flake check --no-build`  
**When:** After show check, validates without building derivations  
**Duration:** 5-15 seconds

### 5. Evaluate Specific Configurations
**Command:** `nix eval --impure .#nixosConfigurations.daedalus.config.system.name`  
**When:** When modifying host configurations  
**Duration:** 10-30 seconds per configuration

### 6. Evaluate Lib Output
**Command:** `nix eval --impure .#lib --apply 'x: builtins.attrNames x'`  
**When:** When modifying `nixos/lib/default.nix`  
**Duration:** 5-10 seconds

### Application Module Structure
Each application in `nixos/modules/applications/` should:
- Have a `default.nix` file (required for imports)
- Use `mySystem.services.<app-name>` or `mySystem.containers.<app-name>` for options
- Follow the pattern: `options` block, then `config` block with `mkIf cfg.enable`
- Use explicit paths when importing other modules

### Import Paths
- Always use explicit `/default.nix` suffixes: `../../applications/media/jellyfin/default.nix`
- Never use directory-only imports: `../../applications/media/jellyfin` (unreliable)
- Relative paths from `nixos/modules/nixos/services/` to `applications/` use `../../applications/`

### Naming Conventions
- Applications use lowercase with hyphens: `browserless-chrome`, `code-server`
- Options use camelCase in config: `config.mySystem.services.browserlessChrome.enable`
- Categories use lowercase: `media`, `productivity`, `infrastructure`

## Testing Strategy

### Pre-Commit Checklist
1. ✅ Run `nix flake check --no-build`
2. ✅ Verify all application imports exist
3. ✅ Check for syntax errors in modified files
4. ✅ Ensure no unreachable applications (all imported or archived)

### Pre-Push Checklist
1. ✅ Run full `nix flake check`
2. ✅ Run `./test-flake.sh` if available
3. ✅ Verify configurations evaluate: `nix eval .#nixosConfigurations.<host>.config.*`

### CI/CD Integration
- GitHub Actions automatically runs `nix flake check` on PRs
- Workflow: `.github/workflows/check-flakes.yaml`
- Triggered on: PR opens, flake file changes, or lock file updates

## Archive Management

Applications in `nixos/modules/applications/_archive/` are:
- Not currently enabled on any host
- Preserved for potential future use
- NOT imported in `nixos/modules/nixos/services/default.nix` or `nixos/modules/nixos/containers/default.nix`

To restore an archived application:
1. Move it from `_archive/` to appropriate category directory in `nixos/modules/applications/`
2. Add import path to `nixos/modules/nixos/services/default.nix` or `nixos/modules/nixos/containers/default.nix`
3. Enable in host configuration

## Notes for AI Assistants

- **Import registry structure:** The `nixos/modules/nixos/services/` and `containers/` directories now only contain `default.nix` import files that reference applications in `nixos/modules/applications/`. All actual application modules have been moved to the categorized `applications/` directory.
- **Always verify imports:** When moving files, check import paths in `nixos/modules/nixos/services/default.nix` and `containers/default.nix`
- **Test incrementally:** Run fast tests first, then comprehensive tests
- **Check dependencies:** Some applications (e.g., rxresume) depend on others (browserless-chrome) - ensure dependencies are also imported
- **Preserve structure:** Keep explicit `/default.nix` paths, don't simplify to directory-only imports
- **Archive unused:** If an application isn't enabled anywhere, move it to `applications/_archive/` and remove its import
- **Validate paths:** Use file existence checks before modifying imports

## Useful Commands

```bash
# Quick validation
nix flake check --no-build

# List all NixOS configurations
nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x'

# Check if an application is imported
grep -r "applications/path/to/app" nixos/modules/nixos/services/default.nix nixos/modules/nixos/containers/default.nix

# Find unreachable applications (not imported in services/containers)
find nixos/modules/applications -name "default.nix" ! -path "*/_archive/*" | \
  while read f; do 
    app=$(dirname "$f" | sed 's|nixos/modules/applications/||'); \
    if ! grep -q "applications/${app}" nixos/modules/nixos/services/default.nix nixos/modules/nixos/containers/default.nix 2>/dev/null; then
      echo "Unreachable: ${app}"
    fi
  done

# Format Nix code
nix fmt
```

