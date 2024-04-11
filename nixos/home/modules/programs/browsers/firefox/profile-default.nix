{ pkgs }:
{
  id = 0;
  name = "default";
  isDefault = true;
  settings = {
    "browser.startup.homepage" = "https://homepage.trux.dev";
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
}
