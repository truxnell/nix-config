# Development Workflow

This document outlines the development processes, testing procedures, and operational workflows for the NixOS homelab configuration.

## Development Environment

### Prerequisites
- Nix with flakes enabled
- SSH access to target hosts
- SOPS age keys configured
- Git for version control

### Development Shell
```bash
# Enter development environment
nix develop

# Development shell provides:
# - Pre-commit hooks
# - Linting tools (statix, deadnix)
# - Formatting tools (alejandra)
# - Deployment tools (deploy-rs)
```

## Code Quality Standards

### Formatting and Linting
```bash
# Format all Nix code
just fmt

# Run linter
just lint

# Check flake structure
just flake-check

# Run all quality checks
just pre-commit-run
```

### Code Standards
- **Readability First**: Use descriptive variable names and clear module structure
- **Error Handling**: Use `assert` for misconfigurations; errors should never pass silently
- **Dependency Management**: Keep functions/dependencies within relevant modules
- **Flat Structure**: Prefer built-in functions (map, filter, fold) over nested logic

## Testing Workflow

### Local Testing
```bash
# Test build without deployment
just build <host>

# Show configuration diff
just diff <host>

# Test configuration locally (containers only)
just test <host>

# Dry run activation (shows what would change)
just dry-activate <host>
```

### Validation Requirements
- **Required**: Always run `nix flake check --impure` for structural/Nix code changes
- **Container Validation**: Validate OCI images using provided scripts
- **Service Testing**: Verify service starts and responds correctly
- **Integration Testing**: Confirm monitoring and backup integration

### Testing Checklist
- [ ] `nix flake check --impure` passes
- [ ] Configuration builds without errors
- [ ] Services start successfully
- [ ] Health checks pass
- [ ] Secrets are properly injected
- [ ] Backups are configured (if applicable)
- [ ] Monitoring is enabled (if applicable)

## Deployment Process

### Development Deployment
```bash
# Deploy to development host
just deploy <host>

# Deploy with extra logging
just deploy-debug <host>

# Deploy specific service changes
just deploy <host> --targets .#nixosConfigurations.<host>.config.services.<service>
```

### Production Deployment
```bash
# 1. Test locally first
just build <host>
just flake-check

# 2. Deploy to staging/test environment if available
just deploy <test-host>

# 3. Verify functionality
curl -f https://service.domain.com/health

# 4. Deploy to production
just deploy <prod-host>

# 5. Monitor deployment
just logs <host>
```

### Rollback Procedure
```bash
# List previous generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo /nix/var/nix/profiles/system-<generation>/bin/switch-to-configuration switch

# Or use deploy-rs rollback
deploy --rollback .#<host>
```

## Service Development

### Adding a New Service

1. **Choose Pattern**: Decide between NixOS module or OCI container
2. **Create Module**: Use appropriate boilerplate from APPLICATION_PATTERNS.md
3. **Configure Secrets**: Add SOPS configuration if needed
4. **Test Locally**: Validate configuration builds
5. **Deploy**: Test on development host first
6. **Integrate**: Add monitoring and backup configuration
7. **Document**: Update any relevant documentation

### Service Development Checklist
- [ ] Service module follows established patterns
- [ ] Standard options are implemented (enable, monitor, backup, etc.)
- [ ] Secrets are properly managed with SOPS
- [ ] Persistence is configured for stateful data
- [ ] Health monitoring is configured
- [ ] Backup strategy is implemented
- [ ] Reverse proxy configuration is added
- [ ] Service is added to host configuration

## Secret Management

### Adding New Secrets
```bash
# Edit secrets file
sops nixos/modules/applications/<category>/<app>/secrets.sops.yaml

# Verify secret encryption
sops --decrypt secrets.sops.yaml

# Test secret injection
just deploy <test-host>
```

### Secret Best Practices
- Store secrets alongside the module that uses them
- Use descriptive key names: `services/<app>/<purpose>`
- Include environment variables in `env` format
- Test secret injection after changes
- Rotate secrets regularly

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clear nix cache
sudo nix-collect-garbage -d

# Rebuild flake inputs
nix flake update

# Check for syntax errors
nix flake check --impure
```

#### Deployment Failures
```bash
# Check deployment logs
just logs <host>

# SSH to host for debugging
ssh <host>

# Check service status
systemctl status <service>

# View service logs
journalctl -u <service> -f
```

#### Secret Issues
```bash
# Verify SOPS configuration
sops --config .sops.yaml --decrypt <secrets-file>

# Check age key configuration
age-keygen -y ~/.config/sops/age/keys.txt

# Verify secret file permissions
ls -la /run/secrets/
```

### Debugging Commands
```bash
# Check system configuration
nixos-rebuild dry-activate

# View current generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Check service dependencies
systemctl list-dependencies <service>

# View full system logs
journalctl -f

# Check network connectivity
systemctl status systemd-resolved
```

## Maintenance Procedures

### Regular Maintenance
```bash
# Update flake inputs (weekly)
just update

# Clean old generations (monthly)
just gc

# Update container images (as needed)
# Edit image tags in modules and redeploy

# Review and rotate secrets (quarterly)
# Update SOPS files and redeploy affected services
```

### System Updates
```bash
# 1. Update inputs
nix flake update

# 2. Test locally
just build <host>

# 3. Deploy to test environment
just deploy <test-host>

# 4. Verify all services
# Check monitoring dashboards

# 5. Deploy to production
just deploy <prod-host>

# 6. Monitor for issues
# Watch logs and metrics
```

### Backup Verification
```bash
# Test backup restoration
restic -r <repo> snapshots
restic -r <repo> restore <snapshot> --target /tmp/restore-test

# Verify database backups
sudo -u postgres pg_dump <database> > /tmp/test-dump.sql
```

## Performance Optimization

### Build Performance
- Use binary caches when available
- Leverage remote builders for heavy builds
- Keep flake inputs updated but stable

### Deployment Performance
- Use `--fast-connection` for local deployments
- Deploy incrementally when possible
- Monitor deployment times and optimize bottlenecks

### Resource Usage
- Monitor container resource usage
- Optimize service configurations
- Use resource limits where appropriate

## Documentation Standards

### Code Documentation
- Use clear variable names
- Add comments for complex logic
- Document non-obvious configuration choices
- Keep README files updated

### Change Documentation
- Use descriptive commit messages
- Document breaking changes
- Update relevant documentation files
- Note any required manual steps

## Collaboration Guidelines

### Git Workflow
- Use feature branches for new services
- Write descriptive commit messages
- Test changes before pushing
- Use pull requests for review

### Code Review
- Focus on security implications
- Verify configuration follows patterns
- Check for proper secret management
- Ensure monitoring and backup coverage

This development workflow ensures reliable, maintainable infrastructure while allowing for rapid iteration and testing.