{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.redlib;
in
{
  options.mySystem.services.redlib.enable = mkEnableOption "redlib";

  # fuck /u/spez
  config =
    config.lib.mySystem.mkService
      {
        app = "redlib";
        image = "quay.io/redlib/redlib@sha256:7fa92bb9b5a281123ee86a0b77a443939c2ccdabba1c12595dcd671a84cd5a64";
        port = 8080;
        container = {
          env = {
            REDLIB_DEFAULT_SHOW_NSFW = "on";
            REDLIB_DEFAULT_WIDE = "on";
            REDLIB_DEFAULT_USE_HLS = "on";
            REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
          };

        };
      };

}
