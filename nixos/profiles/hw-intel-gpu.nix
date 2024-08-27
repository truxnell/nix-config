  { config, lib, pkgs, imports, boot, ... }:

with lib;
{
  
  # Enable intel igpu
  boot.kernelParams = [
    "i915.enable_guc=2"
  ];

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };

}
