{ config, ... }:
{

  sops.age.sshKeyPaths = [ "${config.mySystem.system.impermanence.sshPath}/ssh_host_ed25519_key" ];
  # Secret for machine-specific pushover
  sops.secrets."services/pushover/env" = {

    sopsFile = ./secrets.sops.yaml;
  };

}
