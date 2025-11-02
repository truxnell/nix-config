# Testing Guide

This guide covers the testing infrastructure and procedures for this NixOS homelab configuration repository.

## Testing Philosophy

Our testing strategy focuses on:
- **Fast feedback**: Quick syntax and structure validation
- **Configuration validation**: Ensuring all hosts and modules evaluate correctly
- **Import integrity**: Verifying all module imports resolve
- **CI/CD integration**: Automated checks on pull requests

## Test Types

### 1. Syntax Validation

**Purpose**: Catch basic syntax errors before deeper evaluation.

**Command**:
```bash
nix-instantiate --parse flake.nix > /dev/null
```

**When to run**: Before any other test, catches syntax errors immediately.

**Duration**: < 1 second

### 2. Flake Structure Validation

**Purpose**: Verify flake metadata and outputs are accessible.

**Commands**:
```bash
# Check metadata
nix flake metadata --no-write-lock-file

# List outputs
nix flake show --no-write-lock-file
```

**When to run**: After syntax check, validates flake structure.

**Duration**: 2-5 seconds each

### 3. Configuration Evaluation

**Purpose**: Ensure all NixOS configurations can be evaluated without errors.

**Commands**:
```bash
# Evaluate specific host
nix eval --impure .#nixosConfigurations.daedalus.config.system.name

# Evaluate all hosts
for host in daedalus shodan; do
  nix eval --impure ".#nixosConfigurations.${host}.config.system.name"
done
```

**When to run**: When modifying host configurations or modules.

**Duration**: 10-30 seconds per configuration

### 4. Comprehensive Test Script

**Purpose**: Run all validation tests in sequence.

**Command**:
```bash
./test-flake.sh
```

**What it checks**:
- Syntax validation
- Flake metadata
- Flake outputs
- Flake check (no build)
- Host configuration evaluation
- Lib output validation
- Application import validation
- SOPS secrets encryption state

**When to run**: Before committing significant changes, pre-push.

**Duration**: 30-60 seconds

**Exit codes**:
- `0`: All tests passed
- `1`: One or more tests failed

### 5. Nix Expression Tests

**Purpose**: Validate flake outputs and structure.

**Command**:
```bash
nix eval --impure -f test-nix-expressions.nix
```

**What it validates**:
- All hosts are accessible
- Formatter is defined
- Lib output exists
- DevShells are defined

**When to run**: When modifying flake structure or outputs.

**Duration**: 5-10 seconds

### 6. Import Path Validation

**Purpose**: Verify all module imports point to existing files.

**Manual check**:
```bash
# Check service imports
grep -E "applications/[^/]+/[^/]+" nixos/modules/nixos/services/default.nix | \
  while read line; do
    app=$(echo "$line" | sed 's|.*applications/||; s|/default.nix.*||')
    if [ ! -f "nixos/modules/applications/${app}/default.nix" ]; then
      echo "ERROR: Missing ${app}"
    fi
  done
```

**When to run**: After moving or restructuring application modules.

**Automated**: Included in `test-flake.sh`

### 7. Flake Check (Full)

**Purpose**: Complete flake validation including build checks.

**Command**:
```bash
nix flake check
```

**Warning**: This may take longer as it can trigger builds. Use `--no-build` for faster validation.

**When to run**: Before important deployments, in CI/CD.

**Duration**: Varies (can be minutes)

## Testing Workflow

### Pre-Commit Checklist

Before committing changes:

1. ✅ Run `nix fmt` to format code
2. ✅ Run `just lint` to check for linting issues
3. ✅ Run `nix flake check --no-build` for fast validation
4. ✅ Run `./test-flake.sh` for comprehensive validation

### Pre-Push Checklist

Before pushing to remote:

1. ✅ All pre-commit checks pass
2. ✅ Run full `nix flake check` (if time permits)
3. ✅ Verify specific configurations evaluate if modified

### CI/CD Integration

GitHub Actions automatically runs:

- `nix flake check` on pull requests
- Additional validation in enhanced workflows (see `.github/workflows/test-suite.yaml`)

## Using Justfile Commands

The repository includes convenient Justfile commands:

```bash
# Format code
just fmt

# Run linting
just lint

# Run lint + pre-commit
just check

# Build configuration for a host
just build <host>

# Test build (doesn't apply)
just test <host>
```

## Troubleshooting

### "option does not exist" Errors

**Cause**: Application module not imported in `services/default.nix` or `containers/default.nix`

**Solution**: Add the import path with explicit `/default.nix` suffix:
```nix
../../applications/media/jellyfin/default.nix
```

### "File does not exist" Errors

**Cause**: Incorrect relative paths after restructuring

**Solution**: Verify paths use explicit `/default.nix` suffixes, check relative path from import location

### SOPS Secrets Errors

**Cause**: Secrets not encrypted or missing keys

**Solution**: Ensure secrets are encrypted with `sops --encrypt` and correct machine keys are available

### Circular Dependency Errors

**Cause**: Modules accessing `config` during option definition

**Solution**: Use `mkOption` with functions, avoid accessing config in option definitions

## Advanced Testing

### VM Testing

For more comprehensive testing, you can build and test in VMs:

```bash
# Build system configuration
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Test in a VM (requires nixos-test)
# nixos-test <configuration>
```

### Dry-Run Deployments

Test deployments without applying:

```bash
# Using deploy-rs
just dry-deploy <host>

# Using nixos-rebuild
just dry-activate <host>
```

## Test Script Output

The `test-flake.sh` script provides clear output:

```
🧪 Running comprehensive flake validation tests...

1️⃣  Checking Nix syntax...
✅ Syntax check passed

2️⃣  Validating flake metadata...
✅ Flake metadata valid

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All validation tests passed!
```

Failures will indicate which step failed for easy debugging.

## Continuous Improvement

Test coverage should expand as the repository grows:

- Consider adding module-specific tests
- Evaluate adding VM-based integration tests
- Expand CI/CD test matrix for different scenarios

