{ inputs
, ...
}:
{
  # deploy-rs overlay
  deploy-rs = inputs.deploy-rs.overlays.default;

  nur = inputs.nur.overlay;

  # The unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
