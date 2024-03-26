{ lib
, config
, ...
}:
with lib;
let
  cfg = config.mySystem.security;
in
{
  options.mySystem.security = {

    sshAgentAuth.enable = lib.mkEnableOption "openssh";

    wheelNeedsSudoPassword = lib.mkOption {
      type = lib.types.bool;
      description = "If wheel group users need password for sudo";
      default = true;
    };
    increaseWheelLoginLimits = lib.mkOption {
      type = lib.types.bool;
      description = "If wheel group users receive increased login limits";
      default = true;
    };
  };

  config =
    {
      security = {
        sudo.wheelNeedsPassword = cfg.wheelNeedsSudoPassword;

        pam.enableSSHAgentAuth = cfg.sshAgentAuth.enable;

        # Increase open file limit for sudoers
        pam.loginLimits = mkIf cfg.increaseWheelLoginLimits [
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
    };

}
