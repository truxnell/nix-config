## Profiles

Here is the profiles that each host picks from to build up a system.

My headspace for this to have be able to have a set of modular components pull together on a granular system from this nix, from 'Everything will have this set' to per-device config.
Where possible ill use the `mySystem` option list to configure defaults via these profiles, so they _can_ be overridden later. If its not worth writing a custom module for a nixos feature I may just set it directly in the profile.

## Global

Default global settings that will apply to every device. Things like locale, timezone, etc that wont change machine to machine

## Hardware

Hardware settings so I can apply per set of machines as standard- i.e. all Raspi4's may benefit from a specific set of additions/hardware overlays.

## Role

The role the machine have. Machines may have multiple roles
i.e. servers will want to have bare minimal, remote build settings, where as main desktop/laptop will have full blow GUIs.
