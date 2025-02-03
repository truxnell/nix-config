{ inputs
, ...
}:
{

  nur = inputs.nur.overlays.default;

  # The unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
  nixpkgs-overlays = final: prev: {
    snapraid-btrfs = prev.callPackage ../pkgs/snapraid-btrfs.nix { };
    snapraid-btrfs-runner = prev.callPackage ../pkgs/snapraid-btrfs-runner.nix { };
    podman-containers = prev.callPackage ../pkgs/cockpit-podman.nix { };
    podman-sensors = prev.callPackage ../pkgs/cockpit-sensors.nix { };
    podman-files = prev.callPackage ../pkgs/cockpit-files.nix { };

  };
}
