{ pkgs }:
{
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
      urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
      iconUpdateURL = "https://wiki.nixos.org/favicon.ico";
      updateInterval = 24 * 60 * 60 * 1000; # every day
      definedAliases = [ "@nw" ];
    };
    "KubeSearch" = {
      urls = [{ template = "https://kubesearch.dev/#{searchTerms}"; }];
      iconUpdateURL = "https://kubernetes.io/images/wheel.svg";
      updateInterval = 24 * 60 * 60 * 1000; # every day
      definedAliases = [ "@ks" ];
    };
    "Github Code Search" = {
      urls = [{ template = "https://github.com/search?type=code&q={searchTerms}"; }];
      iconUpdateURL = "https://github.githubassets.com/favicons/favicon-dark.svg";
      updateInterval = 24 * 60 * 60 * 1000; # every day
      definedAliases = [ "@gs" ];
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
}
