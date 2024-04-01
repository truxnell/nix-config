{ lib
, config
, pkgs
, ...
}:

with lib;
# let
#   cfg = config.mySystem.xx.yy;
# in
{

  imports = [
    ./traefik
  ];

  options.myLab.containers.fileRoot = mkOption {
    type = lib.types.str;
    description = "root file path for containers";
    default = "/persistence/containers/";
  };

  # Email
  options.myLab.email.adminFromAddr = mkOption {
    type = lib.types.str;
    description = "From address for admin emails";
    default = "";
  };
  options.myLab.email.adminToAddr = mkOption {
    type = lib.types.str;
    description = "Address for admin emails to be sent to";
    default = "admin@trux.dev";
  };
  options.myLab.email.smtpServer = mkOption {
    type = lib.types.str;
    description = "SMTP server address";
    default = "";
  };

  config = mkIf cfg.enable {

    # CONFIG HERE
    myLab.email.adminFromAddr = "admin@trux.dev";
    myLab.email.smtpServer = "dns02"; # forwards to maddy relay

  };


}
