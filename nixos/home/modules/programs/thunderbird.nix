{ lib
, config
, self
, pkgs
, osConfig
, ...
}:
with lib; let
  app = "thunderbird";
  cfg = config.myHome.programs.${app};
in
{
  options.myHome.programs.${app} =
    {
      enable = mkEnableOption "${app}";
    };

  config.programs.${app} = mkIf cfg.enable {

    enable = true;
    package = pkgs.unstable.thunderbird;
  };

}
