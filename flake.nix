{
  description = "My nixos homelab";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # impermanence
    # https://github.com/nix-community/impermanence
    impermanence.url = "github:nix-community/impermanence";

    # nur
    nur.url = "github:nix-community/NUR";

    # nix-community hardware quirks
    # https://github.com/nix-community
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager - home user+dotfile manager
    # https://github.com/nix-community/home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix - secrets with mozilla sops
    # https://github.com/Mic92/sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VSCode community extensions
    # https://github.com/nix-community/nix-vscode-extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-index database
    # https://github.com/nix-community/nix-index-database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-inspect = {
      url = "github:bluskript/nix-inspect";
    };
  };
  outputs =
    { self
    , nixpkgs
    , sops-nix
    , home-manager
    , nix-vscode-extensions
    , impermanence
    , ...
    } @ inputs:

    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];

    in
    rec {
      # Use nixpkgs-fmt for 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);


      # extend lib with my custom functions
      lib = nixpkgs.lib.extend (
        final: prev: {
          inherit inputs;
          myLib = import ./nixos/lib { inherit inputs; lib = final; };
        }
      );

      nixosConfigurations =
        with self.lib;
        let
          specialArgs = {
            inherit inputs outputs;
          };
          # Import overlays for building nixosconfig with them.
          overlays = import ./nixos/overlays { inherit inputs; };

          # generate a base nixos configuration with the
          # specified overlays, hardware modules, and any extraModules applied
          mkNixosConfig =
            { hostname
            , system ? "x86_64-linux"
            , nixpkgs ? inputs.nixpkgs
            , hardwareModules ? [ ]
              # basemodules is the base of the entire machine building
              # here we import all the modules and setup home-manager
            , baseModules ? [
                sops-nix.nixosModules.sops
                home-manager.nixosModules.home-manager
                impermanence.nixosModules.impermanence
                ./nixos/profiles/global.nix # all machines get a global profile
                ./nixos/modules/nixos # all machines get nixos modules
                ./nixos/hosts/${hostname}   # load this host's config folder for machine-specific config
                {
                  home-manager = {
                    useUserPackages = true;
                    useGlobalPkgs = true;
                    extraSpecialArgs = {
                      inherit inputs hostname system;
                    };

                  };
                }
              ]
            , profileModules ? [ ]
            }:
            nixpkgs.lib.nixosSystem {
              inherit system lib;
              modules = baseModules ++ hardwareModules ++ profileModules;
              specialArgs = { inherit self inputs nixpkgs; };
              # Add our overlays

              pkgs = import nixpkgs {
                inherit system;
                overlays = builtins.attrValues overlays;
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = _: true;
                };
              };

            };
        in
        rec {

          "rickenbacker" = mkNixosConfig {
            # NixOS laptop (dualboot windows, dunno why i kept it)
            hostname = "rickenbacker";
            system = "x86_64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-thinkpad-e14-amd.nix
              inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd
            ];
            profileModules = [
              ./nixos/profiles/role-worstation.nix
              ./nixos/profiles/role-dev.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/workstation.nix; }


            ];
          };

          "citadel" = mkNixosConfig {
            # Gaming PC (dualboot windows)

            hostname = "citadel";
            system = "x86_64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-gaming-desktop.nix
            ];
            profileModules = [
              ./nixos/profiles/role-worstation.nix
              ./nixos/profiles/role-dev.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/workstation.nix; }

            ];

          };

          # "dns01" = mkNixosConfig {
          #   # Rpi for DNS and misc services

          #   hostname = "dns01";
          #   system = "aarch64-linux";
          #   hardwareModules = [
          #     ./nixos/profiles/hw-rpi4.nix
          #     inputs.nixos-hardware.nixosModules.raspberry-pi-4
          #   ];
          #   profileModules = [
          #     ./nixos/profiles/role-server.nix
          #     { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }

          #   ];
          # };

          # "dns02" = mkNixosConfig {
          #   # Rpi for DNS and misc services

          #   hostname = "dns02";
          #   system = "aarch64-linux";
          #   hardwareModules = [
          #     ./nixos/profiles/hw-rpi4.nix
          #     inputs.nixos-hardware.nixosModules.raspberry-pi-4
          #   ];
          #   profileModules = [
          #     ./nixos/profiles/role-server.nix
          #     { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
          #   ];
          # };

          # "durandal" = mkNixosConfig {
          #   # test lenovo tiny

          #   hostname = "durandal";
          #   system = "x86_64-linux";
          #   hardwareModules = [
          #     ./nixos/profiles/hw-generic-x86.nix
          #   ];
          #   profileModules = [
          #     ./nixos/profiles/role-server.nix
          #     ./nixos/profiles/role-dev.nix
          #     { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
          #   ];
          # };

          "daedalus" = mkNixosConfig {
            # lenovo tiny 720q NAS

            hostname = "daedalus";
            system = "x86_64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-generic-x86.nix
            ];
            profileModules = [
              ./nixos/profiles/role-server.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
            ];
          };

          "shodan" = mkNixosConfig {
            # nuc11i7beh (?) homelab

            hostname = "shodan";
            system = "x86_64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-generic-x86.nix
            ];
            profileModules = [
              ./nixos/profiles/role-server.nix
              ./nixos/profiles/role-dev.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
            ];
          };

          "playsatan" = mkNixosConfig {
            # nuci5 tv streaming

            hostname = "playsatan";
            system = "x86_64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-generic-x86.nix
            ];
            profileModules = [
              ./nixos/profiles/role-server.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
            ];
          };





        };




      # # nix build .#images.rpi4
      # rpi4 = nixpkgs.lib.nixosSystem {
      #   inherit specialArgs;

      #   modules = defaultModules ++ [
      #     "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      #     ./nixos/hosts/images/sd-image
      #   ];
      # };
      # # nix build .#images.iso
      # iso = nixpkgs.lib.nixosSystem {
      #   inherit specialArgs;

      #   modules = defaultModules ++ [
      #     "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
      #     "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
      #     ./nixos/hosts/images/cd-dvd
      #   ];
      # };

      # simple shortcut to allow for easier referencing of correct
      # key for building images
      # > nix build .#images.rpi4
      # images.rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
      # images.iso = nixosConfigurations.iso.config.system.build.isoImage;

      # Convenience output that aggregates the outputs for home, nixos.
      # Also used in ci to build targets generally.
      top =
        let
          nixtop = nixpkgs.lib.genAttrs
            (builtins.attrNames inputs.self.nixosConfigurations)
            (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
        in
        nixtop;
    };

}
