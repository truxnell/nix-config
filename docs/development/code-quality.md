# Code Quality Standards

This document outlines code quality standards, linting rules, and best practices for this repository.

## Overview

We maintain high code quality through automated tooling, clear conventions, and best practices. All code should be:

- **Readable**: Clear structure and naming
- **Maintainable**: Well-organized and documented
- **Consistent**: Follows established patterns
- **Tested**: Validated through our testing infrastructure

## Linting Tools

### Nix Linting

#### Statix

**Purpose**: Find and fix antipatterns in Nix code.

**Usage**:
```bash
# Check for issues
statix check .

# Check specific path
statix check nixos/

# Auto-fix issues (use with caution)
statix fix .
```

**Via Justfile**:
```bash
just lint
```

**Configuration**: Uses default statix rules. Consider adding `.statix.toml` for custom rules if needed.

#### Deadnix

**Purpose**: Find unused Nix code (let bindings, function arguments, etc.).

**Usage**:
```bash
deadnix .
```

**Integration**: Available in devShell, can be added to pre-commit if desired.

### YAML Linting

**Tool**: `yamllint`

**Configuration**: `.github/lint/.yamllint.yaml`

**Usage**: Automatically runs via pre-commit hooks.

### Secret Detection

**Tool**: `gitleaks`

**Purpose**: Prevent accidental commits of secrets, API keys, passwords, etc.

**Usage**: Automatically runs via pre-commit hooks.

**Configuration**: Uses default patterns. Consider adding `.gitleaksignore` for false positives.

## Pre-Commit Hooks

Pre-commit hooks automatically run checks before commits.

### Setup

```bash
just pre-commit-init
```

This installs hooks and dependencies.

### Available Hooks

Current hooks configured in `.pre-commit-config.yaml`:

1. **yamllint**: YAML syntax and style
2. **trailing-whitespace**: Remove trailing whitespace
3. **end-of-file-fixer**: Ensure files end with newline
4. **fix-byte-order-marker**: Remove BOM characters
5. **mixed-line-ending**: Enforce consistent line endings
6. **check-added-large-files**: Prevent large file commits (>2MB)
7. **check-merge-conflict**: Detect merge conflict markers
8. **check-executables-have-shebangs**: Verify executable files have shebangs
9. **remove-crlf**: Remove Windows line endings
10. **remove-tabs**: Remove tabs (except Makefiles)
11. **gitleaks**: Detect secrets
12. **sops-encryption**: Verify SOPS files are encrypted

### Running Manually

```bash
# Run on all files
just pre-commit-run

# Run on staged files only
pre-commit run

# Run specific hook
pre-commit run yamllint
```

### Updating Hooks

```bash
just pre-commit-update
```

## Code Style Guidelines

### Nix Code Style

#### Module Structure

Each application module should follow this structure:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.services.<app-name>;
in
{
  options.mySystem.services.<app-name> = {
    enable = lib.mkEnableOption "<app description>";
    # Additional options...
  };

  config = lib.mkIf cfg.enable {
    # Configuration...
  };
}
```

#### Import Paths

**Always use explicit paths with `/default.nix`:**

```nix
# ✅ Good
../../applications/media/jellyfin/default.nix

# ❌ Bad (unreliable)
../../applications/media/jellyfin
```

#### Naming Conventions

- **Applications**: lowercase with hyphens (`browserless-chrome`, `code-server`)
- **Options**: camelCase in config (`config.mySystem.services.browserlessChrome.enable`)
- **Categories**: lowercase (`media`, `productivity`, `infrastructure`)

#### Option Definitions

```nix
# ✅ Good - use mkEnableOption for boolean flags
enable = lib.mkEnableOption "description";

# ✅ Good - type-safe options
port = lib.mkOption {
  type = lib.types.port;
  default = 8080;
  description = "Port to listen on";
};

# ❌ Bad - accessing config during option definition
enable = lib.mkOption {
  default = config.mySystem.enableAll;
};
```

### YAML Code Style

- Use 2 spaces for indentation
- No trailing whitespace
- Consistent quoting (prefer no quotes unless needed)
- Document complex structures

### Documentation Style

- Use clear, concise language
- Include examples where helpful
- Keep documentation up-to-date with code changes
- Use proper Markdown formatting

## Best Practices

### Module Organization

1. **One module per application**: Each app gets its own directory
2. **Consistent structure**: Follow established patterns
3. **Clear dependencies**: Import dependencies explicitly
4. **Archive unused**: Move unused modules to `_archive/`

### Error Handling

- Use `mkIf` for conditional configuration
- Provide clear error messages
- Validate inputs where possible

### Performance

- Avoid unnecessary evaluations
- Use lazy evaluation where appropriate
- Cache expensive computations

### Security

- Never commit secrets (use SOPS)
- Validate user inputs
- Follow principle of least privilege
- Keep dependencies updated

## Code Review Guidelines

When reviewing code:

1. **Functionality**: Does it work as intended?
2. **Style**: Follows coding standards?
3. **Tests**: Includes appropriate tests?
4. **Documentation**: Updated documentation?
5. **Security**: No security concerns?
6. **Performance**: No obvious performance issues?

## Continuous Improvement

Code quality is an ongoing process:

- Regularly update linting rules
- Refactor when patterns emerge
- Document decisions and trade-offs
- Share knowledge with the team

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Statix Documentation](https://github.com/nerdypepper/statix)
- [Pre-commit Documentation](https://pre-commit.com/)

