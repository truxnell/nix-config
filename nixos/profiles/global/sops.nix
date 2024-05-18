{ config, ... }:
{

  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  # Secret for machine-specific pushover
  sops.secrets."services/pushover/env" = {
    sopsFile = ./secrets.sops.yaml;
  };
  sops.secrets.pushover-user-key = {
    sopsFile = ./secrets.sops.yaml;
  };
  sops.secrets.pushover-api-key = {
    sopsFile = ./secrets.sops.yaml;
  };

}
