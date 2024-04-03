
* Dont make conditional imports (nix needs to resolve imports upfront)
* can pass between nixos and home-manager with config.homemanager.users.<X>.<y> and osConfig.<x?
* when adding home-manager to existing setup, the home-manager service may fail due to trying to over-write existing files in `~`.  Deleting these should allow the service to start
