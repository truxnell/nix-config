{ config, lib, pkgs, ... }:

with lib;
let cfg = config.mySystem.profiles.global;
in
{
  options.mySystem.profiles.global.enable = mkEnableOption "Global profile" // { default = true; };

  config = mkIf cfg.enable
    {
      mySystem.time.timeZone = "Australia/Melbourne";

      i18n = {
        defaultLocale = lib.mkDefault "en_AU.UTF-8";
      };
    };
}
