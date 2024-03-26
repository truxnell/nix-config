{ lib
, config
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.services.rebootRequiredCheck;
in
{
  options.mySystem.services.rebootRequiredCheck.enable = mkEnableOption "Reboot required check";

  config = mkIf cfg.enable {

    # Enable timer
    systemd.timers."reboot-required-check" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # start at boot
        OnBootSec = "0m";
        # check every hour
        OnUnitActiveSec = "1h";
        Unit = "reboot-required-check.service";
      };
    };

    # Below script will check if initrd, kernel, kernel-modules that were booted match the current system
    # i.e. if a  nixos-rebuild switch has upgraded anything
    systemd.services."reboot-required-check" = {
      script = ''
        #!/usr/bin/env bash

        # compare current system with booted sysetm to determine if a reboot is required
        if [[ "$(readlink /run/booted-system/{initrd,kernel,kernel-modules})" == "$(readlink /run/current-system/{initrd,kernel,kernel-modules})" ]]; then
          # check if the '/var/run/reboot-required' file exists and if it does, remove it
          if [[ -f /var/run/reboot-required ]]; then
            rm /var/run/reboot-required || { echo "Failed to remove /var/run/reboot-required"; exit 1; }
          fi
        else
          echo "reboot required"
          touch /var/run/reboot-required || { echo "Failed to create /var/run/reboot-required"; exit 1; }
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };


  };


}
