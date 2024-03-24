{ lib
, config
, ...
}:
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

  config =
    {
      security.pam.enableSSHAgentAuth = lib.mkIf cfg.sshAgentAuth.enable true;
      security.sudo.wheelNeedsPassword = lib.mkIf cfg.wheelNeedsSudoPassword true;

    };


}
