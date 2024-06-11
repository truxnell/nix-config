{ lib
, config
, self
, ...
}:
with lib;
let
  cfg = config.mySystem.services.openssh;
in
{
  options.mySystem.services.openssh = {
    enable = mkEnableOption "openssh" // { default = true; };
    passwordAuthentication = mkOption
      {
        type = lib.types.bool;
        description = "If password can be accepted for ssh (commonly disable for security hardening)";
        default = false;

      };
    permitRootLogin = mkOption
      {
        type = types.enum [ "yes" "without-password" "prohibit-password" "forced-commands-only" "no" ];
        description = "If root can login via ssh (commonly disable for security hardening)";
        default = "no";

      };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      openFirewall = true;
      # TODO: Enable this when option becomes available
      # Don't allow home-directory authorized_keys
      authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
      settings = {
        # Harden
        PasswordAuthentication = cfg.passwordAuthentication;
        PermitRootLogin = cfg.permitRootLogin;
        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
      };

    };

  };
}
