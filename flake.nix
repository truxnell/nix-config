{
  description = "My nixos homelab";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # nur
    nur.url = "github:nix-community/NUR";

    # nix-community hardware quirks
    # https://github.com/nix-community
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager - home user+dotfile manager
    # https://github.com/nix-community/home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix - secrets with mozilla sops
    # https://github.com/Mic92/sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # deploy-rs - Remote deployment
    # https://github.com/serokell/deploy-rs
    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
  };
  outputs =
    { self
    , nixpkgs
    , sops-nix
    , deploy-rs
    , home-manager
    , nix-vscode-extensions
    , ...
    } @ inputs:

    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];

    in
    {
      # Use nixpkgs-fmt for 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

      # setup devshells against shell.nix
      devShells = forAllSystems (pkgs: import ./shell.nix { inherit pkgs; });


      nixosConfigurations =
        # with self.lib;
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
              inherit system;
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
              { home-manager.users.truxnell = ./nixos/home/truxnell/workstation.nix; }

            ];

          };

          "dns01" = mkNixosConfig {
            # Rpi for DNS and misc services

            hostname = "dns01";
            system = "aarch64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-rpi4.nix
              inputs.nixos-hardware.nixosModules.raspberry-pi-4
            ];
            profileModules = [
              ./nixos/profiles/role-server.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }

            ];
          };

          "dns02" = mkNixosConfig {
            # Rpi for DNS and misc services

            hostname = "dns02";
            system = "aarch64-linux";
            hardwareModules = [
              ./nixos/profiles/hw-rpi4.nix
              inputs.nixos-hardware.nixosModules.raspberry-pi-4
            ];
            profileModules = [
              ./nixos/profiles/role-server.nix
              { home-manager.users.truxnell = ./nixos/home/truxnell/server.nix; }
            ];
          };

          "durandal" = mkNixosConfig {
            # test lenovo tiny

            hostname = "durandal";
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

      # deploy-rs
      deploy.nodes =
        let
          mkDeployConfig = hostname: configuration: {
            inherit hostname;
            profiles.system =
              let
                inherit (configuration.config.nixpkgs.hostPlatform) system;
              in
              {
                path = inputs.deploy-rs.lib."${system}".activate.nixos configuration;
                sshUser = "truxnell";
                user = "root";
                sshOpts = [ "-t" ];
                autoRollback = false;
                magicRollback = true;
              };
          };
        in
        {
          dns01 = mkDeployConfig "10.8.10.11" self.nixosConfigurations.dns01;
          dns02 = mkDeployConfig "10.8.10.10" self.nixosConfigurations.dns02;
          shodan = mkDeployConfig "10.8.20.33" self.nixosConfigurations.shodan;

          # dns02 = mkDeployConfig "dns02.natallan.com" self.nixosConfigurations.dns02;
        };

      # deploy-rs: This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;

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
