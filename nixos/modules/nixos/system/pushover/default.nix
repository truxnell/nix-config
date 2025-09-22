{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.system.systemd.pushover-alerts;
in
{

  options.mySystem.system.systemd.pushover-alerts.enable = mkEnableOption "Pushover alers for systemd failures" // { default = true; };
  options.systemd.services = mkOption {
    type = with types; attrsOf (
      submodule {
        config.onFailure = [ "notify-pushover@%n.service" ];
      }
    );
  };

  config = {
    # Warn if backups are disable and machine isnt a dev box
    warnings = [
      (mkIf (!cfg.enable && config.mySystem.purpose != "Development") "WARNING: Pushover SystemD notifications are disabled!")
    ];

    systemd.services."notify-pushover@" = mkIf cfg.enable {
      enable = true;
      onFailure = lib.mkForce [ ]; # cant refer to itself on failure
      description = "Notify on failed unit %i";
      serviceConfig = {
        Type = "oneshot";
        # User = config.users.users.truxnell.name;
        EnvironmentFile = config.sops.secrets."services/pushover/env".path;
      };

      # Script calls pushover with some deets.
      # Here im using the systemd specifier %i passed into the script,
      # which I can reference with bash $1.
      scriptArgs = "%i %H";
      script = ''
        ${pkgs.curl}/bin/curl \
          -H "Title: $1 failed" \
          -H "Tags: warning,skull" \
          -d "Journal tail:<br><br>$(journalctl -u $1 -n 10 -o cat)" \
          https://ntfy.trux.dev/homelab 2&>1

      '';
    };

  };
}
