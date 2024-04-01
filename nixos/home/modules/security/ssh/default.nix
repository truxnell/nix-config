{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.myHome.security.ssh;
in
{
  options.myHome.security.ssh = {
    enable = mkEnableOption "ssh";
    matchBlocks = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      inherit (cfg) matchBlocks;
      enable = true;
      # addKeysToAgent = "yes";
    };
  };
}
