
* Dont make conditional imports (nix needs to resolve imports upfront)
* can pass between nixos and home-manager with config.homemanager.users.<X>.<y> and osConfig.<x?
* when adding home-manager to existing setup, the home-manager service may fail due to trying to over-write existing files in `~`.  Deleting these should allow the service to start
* yaml = json, so using nix + builtins.toJSON a lot (and repl to vscode for testing)

checking values:
# https://github.com/NixOS/nixpkgs/blob/90055d5e616bd943795d38808c94dbf0dd35abe8/nixos/modules/config/users-groups.nix#L116
