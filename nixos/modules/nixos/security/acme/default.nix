{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.security.acme;
  app = "acme";
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  user = app;
  group = app;

in
{
  options.mySystem.security.acme.enable = mkEnableOption "acme";

  config = mkIf cfg.enable {
    sops.secrets = {
      "security/acme/env".sopsFile = ./secrets.sops.yaml;
      "security/acme/env".restartUnits = [ "${app}.service" ];
    };

    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [ "/var/lib/acme" ];
    };


    security.acme = {
      acceptTerms = true;
      defaults.email = "admin@${config.networking.domain}";

      certs.${config.networking.domain} = {
        extraDomainNames = [
          "${config.networking.domain}"
          "*.${config.networking.domain}"
        ];
        dnsProvider = "cloudflare";
        dnsResolver = "1.1.1.1:53";
        credentialsFile = config.sops.secrets."security/acme/env".path;
      };
    };


  };
}
