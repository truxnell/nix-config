{ outputs
, lib
, config
, ...
}:
let
  inherit (config.networking) hostName;
  hosts = outputs.nixosConfigurations;
in
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

    };
  };

  security.pam.enableSSHAgentAuth = true;

}
