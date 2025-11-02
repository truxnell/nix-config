## Profiles

Here is the profiles that each host picks from to build up a system.

My headspace for this to have be able to have a set of modular components pull together on a granular system from this nix, from 'Everything will have this set' to per-device config.
Where possible ill use the `mySystem` option list to configure defaults via these profiles, so they _can_ be overridden later. If its not worth writing a custom module for a nixos feature I may just set it directly in the profile.

## Global

Default global settings that will apply to every device. Things like locale, timezone, boot configuration, and hardware platform settings that apply to all machines.

## Role

The role the machine have. Machines may have multiple roles
i.e. servers will want to have bare minimal, remote build settings, where as main desktop/laptop will have full blow GUIs.

Current role profiles:
- `role-server.nix` - Headless server configuration with monitoring, minimal packages, etc.
- `role-dev.nix` - Development tools and utilities
