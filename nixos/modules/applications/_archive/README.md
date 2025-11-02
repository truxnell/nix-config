# Archived Applications

Applications in this directory are not currently enabled on any host but are preserved for potential future use.

## Services
- glance - Not enabled
- glances - Not enabled  
- jellyseer - Commented out in daedalus config
- maintainerr - Commented out in daedalus config
- redis - Not enabled
- traefik - Not imported in services/default.nix (unreachable)

To restore an archived application:
1. Move it back to appropriate category in `applications/`
2. Re-add import in `nixos/modules/nixos/services/default.nix` or `containers/default.nix`
3. Enable in host configuration

