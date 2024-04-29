{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.postgresql;
in
{
  options.mySystem.services.postgresql.enable = mkEnableOption "postgresql";

  config = mkIf cfg.enable {

    services.postgresql = {
      enable = true;
      authentication = ''
        local homeassistant homeassistant ident map=ha
      '';
      identMap = ''
        ha root homeassistant
      '';
      ensureDatabases = [ "homeassistant" ];
      ensureUsers = [
        { name = "homeassistant"; ensureDBOwnership = true; }
      ];
    };

  };
}
