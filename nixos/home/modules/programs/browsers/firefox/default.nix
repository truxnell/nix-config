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

  config = mkIf cfg.enable {

    programs.firefox = {
      enable = true;
      enableGnomeExtensions = true;
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
      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;
        settings = {
          "browser.startup.homepage" = "https://search.trux.dev";
          "browser.search.defaultenginename" = "whoogle";
          "browser.search.order.1" = "whoogle";
        };
        search = {
          force = true;
          default = "whoogle";
          order = [ "whoogle" "Searx" "Google" ];
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  { name = "type"; value = "packages"; }
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "Nix Options" = {
              urls = [{
                template = "https://search.nixos.org/options";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
            "Home-Manager Options" = {
              urls = [{
                template = "https://home-manager-options.extranix.com/";
                params = [
                  { name = "query"; value = "{searchTerms}"; }
                ];
              }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nhmo" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            "KubeSearch" = {
              urls = [{ template = "https://kubesearch.dev/#{searchTerms}"; }];
              iconUpdateURL = "https://kubernetes.io/images/wheel.svg";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@ks" ];
            };

            # "Searx" = {
            #   urls = [{ template = "https://searx.trux.dev/?q={searchTerms}"; }];
            #   iconUpdateURL = "https://nixos.wiki/favicon.png";
            #   updateInterval = 24 * 60 * 60 * 1000; # every day
            #   definedAliases = [ "@searx" ];
            # };
            "Bing".metaData.hidden = true;
            "Google".metaData.alias = "@g"; # builtin engines only support specifying one additional alias
          };
        };
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
          vimium
          languagetool # setup against my personal language-tools
          privacy-badger
          link-cleaner

        ];
      };
    };


  };


}
