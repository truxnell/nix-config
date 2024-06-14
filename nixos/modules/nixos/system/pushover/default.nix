{ lib
, config
, pkgs
, ...
}:
# with lib;
# let
#   cfg = config.mySystem.system.systemd.pushover-alerts;
# in
{

  # Letting alertmanager handle this :)

  # options.mySystem.system.systemd.pushover-alerts.enable = mkEnableOption "Pushover alers for systemd failures" // { default = true; };
  # options.systemd.services = mkOption {
  #   type = with types; attrsOf (
  #     submodule {
  #       config.onFailure = [ "notify-pushover@%n.service" ];
  #     }
  #   );
  # };

  # config = {
  #   # Warn if backups are disable and machine isnt a dev box
  #   warnings = [
  #     (mkIf (!cfg.enable && config.mySystem.purpose != "Development") "WARNING: Pushover SystemD notifications are disabled!")
  #   ];

  #   systemd.services."notify-pushover@" = mkIf cfg.enable {
  #     enable = true;
  #     onFailure = lib.mkForce [ ]; # cant refer to itself on failure
  #     description = "Notify on failed unit %i";
  #     serviceConfig = {
  #       Type = "oneshot";
  #       # User = config.users.users.truxnell.name;
  #       EnvironmentFile = config.sops.secrets."services/pushover/env".path;
  #     };

  #     # Script calls pushover with some deets.
  #     # Here im using the systemd specifier %i passed into the script,
  #     # which I can reference with bash $1.
  #     scriptArgs = "%i %H";
  #     script = ''
  #       ${pkgs.curl}/bin/curl --fail -s -o /dev/null \
  #         --form-string "token=$PUSHOVER_API_KEY" \
  #         --form-string "user=$PUSHOVER_USER_KEY" \
  #         --form-string "priority=1" \
  #         --form-string "html=1" \
  #         --form-string "timestamp=$(date +%s)" \
  #         --form-string "url=https://$2:9090/system/services#/$1" \
  #         --form-string "url_title=View in Cockpit" \
  #         --form-string "title=Unit failure: '$1' on $2" \
  #         --form-string "message=<b>$1</b> has failed on <b>$2</b><br><u>Journal tail:</u><br><br><i>$(journalctl -u $1 -n 10 -o cat)</i>" \
  #         https://api.pushover.net/1/messages.json 2&>1

  #     '';
  #   };

  # };
}
