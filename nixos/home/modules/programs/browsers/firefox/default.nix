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
              nativeMessagingHosts = [
                # Gnome shell native connector
                pkgs.gnome-browser-connector
                # plasma connector
                # plasma5Packages.plasma-browser-integration
              ];
            };
          };
        policies = import ./policies.nix;

        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;
          settings = {
            "browser.startup.homepage" = "https://search.trux.dev";
            "browser.search.defaultenginename" = "whoogle";
            "browser.search.order.1" = "whoogle";
            "browser.search.suggest.enabled.private" = false;
            # 0 => blank page
            # 1 => your home page(s) {default}
            # 2 => the last page viewed in Firefox
            # 3 => previous session windows and tabs
            "browser.startup.page" = "3";

            "browser.send_pings" = false;
            # Do not track
            "privacy.donottrackheader.enabled" = "true";
            "privacy.donottrackheader.value" = 1;
            "browser.display.use_system_colors" = "true";

            "browser.display.use_document_colors" = "false";
            "devtools.theme" = "dark";

            "extensions.pocket.enabled" = false;
          };
          search = import ./search.nix { inherit pkgs; };
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
            darkreader
            vimium
            languagetool # setup against my personal language-tools
            privacy-badger
            link-cleaner
            refined-github
          ];
        };


      };


    };
}
