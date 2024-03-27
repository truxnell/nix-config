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

      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "23.11";
    };
  };

  # config.home-manager = {
  #   useUserPackages = true;
  #   useGlobalPkgs = true;
  #   stateVersion = "23.11";

  #   users.truxnell = {



  #       };


  #       shell = {
  #         fish.enable = true;
  #         git = {
  #           enable = true;
  #           username = "truxnell";
  #           email = "19149206+truxnell@users.noreply.github.com";
  #           # allowedSigners = builtins.readFile ./ssh/allowed_signers; TODO fix keys for signing
  #         };
  #       };
  #     };
  #   };
  # };
}

