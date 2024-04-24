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
    myLib.mkService
      {
        app = "Redlib";
        description = "Reddit alternate frontend";
        image = "quay.io/redlib/redlib@sha256:7fa92bb9b5a281123ee86a0b77a443939c2ccdabba1c12595dcd671a84cd5a64";
        port = 8080;
        user = "nobody";
        group = "nobody";
        timeZone = config.time.timeZone;
        domain = config.networking.domain;
        addToHomepage = true;
        homepage.icon = "libreddit.svg";
        container = {
          env = {
            REDLIB_DEFAULT_SHOW_NSFW = "on";
            REDLIB_DEFAULT_USE_HLS = "on";
            REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "on";
          };
          addTraefikLabels = true;
          caps = {
            readOnly = true;
            noNewPrivileges = true;
            dropAll = true;
          };
        };
      };
  # mkService
  # app: App Name, string, required
  # appUrl: App url, string, default "https://APP.DOMAIN"
  # description: App Description, string, required
  # image: Container IMage, string, required
  # port: port, int
  # timeZone: timezone, required
  # domain: domain of app, required
  # addToHomepage: Flag to add to homepage, bool, default false
  ## HOMEPAGE
  # homepage.icon: Icon for homepage listing, string, default "app.svg"

  # user: user to run as, string, default 568
  # group: group to run as, string, default 568
  # envFiles, files to add as env, list of string, default [ TZ = timeZone ]

  ## CONTAINER
  # container.env, env vars for container, attrset, default { }
  # container.addTraefikLabels, flag for adding traefik exposing labels, default true
  # caps.privileged: privileged pod, grant pod high privs, defualt SUPER false.  SUPER DOOPER FALSE
  # caps.readOnly: readonly pod (outside mounted paths etc).  default false
  #


}
