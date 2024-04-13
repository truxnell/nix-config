{ config, ... }:
{

  sops.age.sshKeyPaths = [ "${config.mySystem.system.impermanence.sshPath}/ssh_host_ed25519_key" ];

}
