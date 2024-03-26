{ lib
, config
, ...
}:
let
  cfg = config.mySystem.time;
in
{
  options.mySystem.time = {
    timeZone = lib.mkOption {
      type = lib.types.str;
      description = "Timezone of system";
      default = "Australia/Melbourne";
    };
    hwClockLocalTime = lib.mkOption {
      type = lib.types.bool;
      description = "If hardware clock is set to local time (useful for windows dual boot)";
      default = false;
    };
  };
  config = {
    time.timeZone = cfg.timeZone;
    time.hardwareClockInLocalTime = cfg.hwClockLocalTime;
  };
}
