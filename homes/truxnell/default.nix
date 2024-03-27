{ inputs
, pkgs
, config
, lib
, hostname
, ...
}:
with lib;
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.truxnell = { pkgs, ... }: {

      programs.ssh = {
        enable = true;
        # addKeysToAgent = "yes";

        matchBlocks = {
          citadel = {
            hostname = "citadel";
            port = 22;
            user = "truxnell";
            identityFile = "~/.ssh/id_ed25519";
          };
          rickenbacker = {
            hostname = "rickenbacker";
            port = 22;
            user = "truxnell";
            identityFile = "~/.ssh/id_ed25519";
          };
          pikvm = {
            hostname = "pikvm";
            port = 22;
            user = "truxnell";
            identityFile = "~/.ssh/id_ed25519";
          };

          dns01 = {
            hostname = "dns01";
            port = 22;
            user = "truxnell";
            identityFile = "~/.ssh/id_ed25519";
          };
          dns02 = {
            hostname = "dns02";
            port = 22;
            user = "truxnell";
            identityFile = "~/.ssh/id_ed25519";
          };
        };
      };
      home.packages = with pkgs; [
        discord

      ];
      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "23.11";
    };
  };



}

