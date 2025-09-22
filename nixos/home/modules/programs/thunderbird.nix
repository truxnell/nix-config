{ lib
, ...
}:
with lib; let
  app = "thunderbird";
in
{
  options.myHome.programs.${app} =
    {
      enable = mkEnableOption "${app}";
    };

  # config.programs.${app} = mkIf cfg.enable {

  #   enable = true;
  #   package = pkgs.unstable.thunderbird;
  #   profiles = {
  #     "main" = {
  #       isDefault = true;
  #       settings = {
  #         "calendar.alarms.showmissed" = false;
  #         "calendar.alarms.playsound" = false;
  #         "calendar.alarms.show" = false;
  #       };
  #     };
  #   };
  # };

}
