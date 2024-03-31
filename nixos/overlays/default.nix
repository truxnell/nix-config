{ inputs
, ...
}:
{
  # deploy-rs overlay
  deploy-rs = inputs.deploy-rs.overlays.default;

  # The unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
  rpi4_kernel_fix = final: super: {
    makeModulesClosure = x:
      super.makeModulesClosure (x // { allowMissing = true; });
  };

}
