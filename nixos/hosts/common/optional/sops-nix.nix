{ inputs
, outputs
, config
, ...
}: {
  # SOPS settings
  # https://github.com/Mic92/sops-nix

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
