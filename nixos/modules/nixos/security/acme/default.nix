{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.security.acme;
  app = "acme";
  appFolder = "apps/${app}";
  persistentFolder = "${config.mySystem.persistentFolder}/${appFolder}";
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

    # ensure folder exist and has correct owner/group
    # systemd.tmpfiles.rules = [
    #   "d ${persistentFolder}/${config.networking.domain} 0755 ${user} ${group} -" #The - disables automatic cleanup, so the file wont be removed after a period

    # ];

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
        #  directory = "${persistentFolder}/${config.networking.domain}";
      };
    };


  };
}
