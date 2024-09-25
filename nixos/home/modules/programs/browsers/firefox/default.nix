{ lib
, config
, self
, pkgs
, osConfig
, ...
}:

with lib;
let
  cfg = config.myHome.programs.firefox;
in
{
  options.myHome.programs.firefox.enable = mkEnableOption "Firefox";

  config = mkIf cfg.enable
    {

      programs.firefox = {
        enable = true;
        package = pkgs.firefox.override
          {
            extraPolicies = {
              DontCheckDefaultBrowser = true;
              DisablePocket = true;
              # See nixpkgs' firefox/wrapper.nix to check which options you can use
              nativeMessagingHosts = []
              ++ lib.optionals osConfig.de.gnome pkgs.gnome-browser-connector
              ++ lib.optionals osConfig.de.kde pkgs.gnome-browser-connector
            };
          };
        policies = import ./policies.nix;

        profiles.default = import ./profile-default.nix { inherit pkgs; };



      };


    };
}
