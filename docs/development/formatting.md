# Code Formatting Standards

This document outlines the code formatting standards and tools used in this repository.

## Overview

We maintain consistent code formatting across all files to improve readability and reduce merge conflicts. All formatting is automated through tools configured in the development environment.

## Nix Files

### Tool: `nixpkgs-fmt`

All Nix files are formatted using `nixpkgs-fmt`, which is the standard formatter for Nix code.

### Configuration

The formatter is configured in `flake.nix`:

```nix
formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);
```

### Usage

**Format all Nix files:**
```bash
nix fmt
```

**Format specific files:**
```bash
nix fmt path/to/file.nix
```

**Check formatting (CI mode):**
```bash
nix fmt --check
```

**Via Justfile:**
```bash
just fmt
```

### Pre-commit Integration

The formatter can be run automatically via pre-commit hooks. To set up:

```bash
just pre-commit-init
```

## YAML Files

### Tool: `yamllint`

YAML files are linted using `yamllint` with a custom configuration.

### Configuration

Configuration file: `.github/lint/.yamllint.yaml`

Key rules:
- Line length: disabled (flexibility for long strings)
- Indentation: enabled
- Comments: minimum 1 space from content
- Truthy values: `true`, `false`, `on` allowed

### Exclusions

The following are excluded from YAML linting:
- `.direnv/`
- `.private/`
- `**/*.sops.yaml` (encrypted secrets)

### Usage

**Run manually:**
```bash
yamllint -c .github/lint/.yamllint.yaml <file>
```

**Via pre-commit:**
Automatically runs on commit for changed YAML files.

## Markdown Files

### Standards

While we don't enforce strict Markdown formatting rules, we follow these guidelines:

- Use consistent heading levels
- Wrap long lines at 80-100 characters when practical
- Use proper list formatting
- Include code fences with language identifiers

### Tools

No automated formatter is currently enforced for Markdown, but you can use:

- `prettier` (optional, not configured)
- Manual formatting following the guidelines above

## General Guidelines

### Line Endings

- Unix-style line endings (LF) are preferred
- Pre-commit hooks enforce this automatically

### Trailing Whitespace

- No trailing whitespace allowed
- Pre-commit hooks remove it automatically

### File Encoding

- UTF-8 encoding for all text files
- Byte order markers (BOM) are not allowed
- Pre-commit hooks enforce this

## CI/CD Integration

Formatting checks are integrated into CI/CD workflows:

1. Pre-commit hooks run locally before commits
2. GitHub Actions workflows can run formatting checks
3. PR checks validate formatting compliance

## Troubleshooting

### Formatting conflicts in Git

If you encounter formatting conflicts:

```bash
# Pull latest changes
git pull

# Format all files
nix fmt

# Resolve conflicts and commit
git add .
git commit
```

### Disabling formatting for specific lines

For Nix files, you cannot disable formatting for specific lines with `nixpkgs-fmt`. If you have a valid reason to format differently, document it in a comment.

For YAML files, you can use `# yamllint disable` comments:

```yaml
# yamllint disable-line rule:line-length
very-long-line-that-would-otherwise-violate-line-length
```

