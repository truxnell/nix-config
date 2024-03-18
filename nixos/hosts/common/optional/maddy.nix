{ inputs
, outputs
, config
, ...
}: {
  # init secret
  config.sops.secrets."system/mail/maddy/envFile" = {
    sopsFile = ./maddy.sops.yaml;
    owner = "maddy";
    group = "maddy";
  };

  # Restart dnscrypt when secret changes
  config.sops.secrets."system/mail/maddy/envFile".restartUnits = [ "maddy" ];

  #
  config.services.maddy = {
    enable = true;
    secrets = [ config.sops.secrets."system/mail/maddy/envFile".path ];
    config = builtins.readFile ./maddy.conf;
  };
}
