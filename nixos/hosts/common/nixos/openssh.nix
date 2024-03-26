_:

{

  services.openssh = {
    enable = true;
    settings = {
      # Harden
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
      # Don't allow home-directory authorized_keys
      # authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    };
  };

  # TODO fix pam, wheel no pass is a bit of a hack
  # security.pam.enableSSHAgentAuth = true;

  # TODO remove this hack
  security.sudo.wheelNeedsPassword = false;

}
