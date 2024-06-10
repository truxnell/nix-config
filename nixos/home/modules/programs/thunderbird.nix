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

  config.programs.${app} = lib.mkIf cfg.enable {

    enable = true;
    profiles = {
      "main" = {
        isDefault = true;
        settings = {
          "calendar.alarms.showmissed" = false;
          "calendar.alarms.playsound" = false;
          "calendar.alarms.show" = false;
        };
      };
    };
  };

}
