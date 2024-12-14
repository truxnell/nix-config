{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.hardware.nvidia;
in
{
  options.mySystem.hardware.nvidia.enable = mkEnableOption "NVIDIA config";

  config = mkIf cfg.enable {

    # ref: https://nixos.wiki/wiki/Nvidia
    # Enable OpenGL
    hardware.graphics = {
      enable = true;
    };
    hardware.graphics.extraPackages = with pkgs; [
      vaapiVdpau
    ];

    boot.kernelParams = [    
      "nvidia-drm.fbdev=1" # fix for kde/nvidia?
      "nvidia_drm.modeset=1"
      "NVreg_EnableGpuFirmware=0"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # fix wakeup issues
    ];

    # This is for the benefit of VSCODE running natively in wayland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = true; # fixing wakeup issues

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # package = config.boot.kernelPackages.nvidiaPackages.stable;

      # manual build nvidia driver, works around some wezterm issues
      # https://github.com/wez/wezterm/issues/2011
      package =
        # let
        # rcu_patch = pkgs.fetchpatch {
        #   url = "https://github.com/gentoo/gentoo/raw/c64caf53/x11-drivers/nvidia-drivers/files/nvidia-drivers-470.223.02-gpl-pfn_valid.patch";
        #   hash = "sha256-eZiQQp2S/asE7MfGvfe6dA/kdCvek9SYa/FFGp24dVg=";
        # };
        # in
        config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "550.67";
          sha256_64bit = "sha256-mSAaCccc/w/QJh6w8Mva0oLrqB+cOSO1YMz1Se/32uI=";
          sha256_aarch64 = "sha256-+UuK0UniAsndN15VDb/xopjkdlc6ZGk5LIm/GNs5ivA=";
          openSha256 = "sha256-M/1qAQxTm61bznAtCoNQXICfThh3hLqfd0s1n1BFj2A=";
          settingsSha256 = "sha256-FUEwXpeUMH1DYH77/t76wF1UslkcW721x9BHasaRUaM=";
          persistencedSha256 = "sha256-ojHbmSAOYl3lOi2X6HOBlokTXhTCK6VNsH6+xfGQsyo=";

          # patches = [ rcu_patch ];
        };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";


  };
}
