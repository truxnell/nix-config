{ lib
, config
, ...
}:

with lib;
let
  cfg = config.mySystem.services.maddy;
in
{
  options.mySystem.services.maddy.enable = mkEnableOption "Maddy SMTP Client (Relay)";

  config = mkIf cfg.enable {

    sops.secrets."system/mail/maddy/envFile" = {
      sopsFile = ./maddy.sops.yaml;
      owner = "maddy";
      group = "maddy";
    };

    sops.secrets."system/mail/maddy/envFile".restartUnits = [ "maddy.service" ];

    services.maddy = {
      enable = true;
      openFirewall = true;
      secrets = [ config.sops.secrets."system/mail/maddy/envFile".path ];
      config = builtins.readFile ./maddy.conf;
    };

  };
}
