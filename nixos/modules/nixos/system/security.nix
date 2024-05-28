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
        # Don't bother with the lecture or the need to keep state about who's been lectured
        sudo.extraConfig = "Defaults lecture=\"never\"";

        pam.sshAgentAuth.enable = true;

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
