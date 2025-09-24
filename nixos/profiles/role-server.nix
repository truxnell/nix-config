{ config, lib, pkgs, ... }:
# Role for headless servers
# covers raspi's, sbc, NUC etc, anything
# that is headless and minimal for running services

with lib;
{


  config = {


    # Enable monitoring for remote scraiping
    mySystem.services.monitoring.enable = true;
    mySystem.services.rebootRequiredCheck.enable = true;
    mySystem.security.wheelNeedsSudoPassword = false;
    mySystem.services.cockpit.enable = true;
    mySystem.system.motd.enable = true;
    mySystem.services.gatus.monitors = [{
      name = config.networking.hostName;
      group = "servers";
      url = "icmp://${config.networking.hostName}.${config.mySystem.internalDomain}";
      interval = "1m";
      conditions = [ "[CONNECTED] == true" ];
    }];

    nix.settings = {
      # TODO factor out into mySystem
      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);
    };

    services.logrotate.enable = mkDefault true;

    services.smartd = mkDefault {
      enable = true;
      autodetect = true;
      defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -m root -M exec /run/smartdnotify";
    };

    systemd.services.smartdnotify = {
      description = "Forward smartd alerts to ntfy";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      script = ''
        curl -H "tags:warning" -H "prio:high" \
            -d "$SMARTD_MESSAGE" \
            https://ntfy.trux.dev/smartd
      '';
    };

    # environment.noXlibs = mkDefault true;
    documentation = {
      enable = mkDefault false;
      doc.enable = mkDefault false;
      info.enable = mkDefault false;
      man.enable = mkDefault false;
      nixos.enable = mkDefault false;
    };
    programs.command-not-found.enable = mkDefault false;

    services.pulseaudio.enable = false;

    environment.systemPackages = with pkgs; [
      tmux
      btop
      curl
    ];


    services.udisks2.enable = mkDefault false;
    # xdg = {
    #   autostart.enable = mkDefault false;
    #   icons.enable = mkDefault false;
    #   mime.enable = mkDefault true;
    #   sounds.enable = mkDefault false;
    # };
  };

}
