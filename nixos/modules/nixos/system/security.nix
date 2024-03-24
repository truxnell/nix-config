{ lib
, config
, ...
}:
with lib;
let
  cfg = config.mySystem.security;
in
{
  options.mySystem.security.sshAgentAuth = {
    enable = lib.mkEnableOption "openssh";
  };
  options.mySystem.security.wheelNeedsSudoPassword = lib.mkOption {
    type = lib.types.bool;
    description = "If wheel group users need password for sudo";
    default = true;
  };
  options.mySystem.security.increaseWheelLoginLimits = lib.mkOption {
    type = lib.types.bool;
    description = "If wheel group users receive increased login limits";
    default = true;
  };

  config =
    {
      security.sudo.wheelNeedsPassword = cfg.wheelNeedsSudoPassword;

      security.pam.enableSSHAgentAuth = cfg.sshAgentAuth.enable;

      # Increase open file limit for sudoers
      security.pam.loginLimits = mkIf cfg.increaseWheelLoginLimits [
        {
          domain = "@wheel";
          item = "nofile";
          type = "soft";
          value = "524288";
        }
        {
          domain = "@wheel";
          item = "nofile";
          type = "hard";
          value = "1048576";
        }
      ];
    };

}
