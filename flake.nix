{
  description = "My machines";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # deploy-rs
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # VSCode community extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { self
    , nixpkgs
    , sops-nix
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        # "i686-linux"
        "x86_64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    with inputs; rec {
      # Use nixpkgs-fmt for 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

      # nixosModules = import ./nixos/modules/nixos;

      nixosConfigurations =
        let
          defaultModules =
            (builtins.attrValues nixosModules) ++
            [
              sops-nix.nixosModules.sops
            ];
          specialArgs = {
            inherit inputs outputs;
          };

          # generate a base nixos configuration with the
          # specified overlays, hardware modules, and any extraModules applied
          mkNixosConfig =
            { hostname
            , system ? "x86_64-linux"
            , nixpkgs ? inputs.nixpkgs
            , hardwareModules
            , baseModules ? [
                # home-manager.nixosModules.home-manager
                # ./modules/nixos
                sops-nix.nixosModules.sops
                ./nixos/hosts/${hostname}
              ]
            , extraModules ? [ ]
            }:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = baseModules ++ hardwareModules ++ extraModules;
              specialArgs = { inherit self inputs nixpkgs; };
            };
        in
        {
          nixosvm = nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "x86_64-linux";
            modules = defaultModules ++ [
              ./nixos/hosts/nixosvm
            ];
          };

          # rickenbacker = nixpkgs.lib.nixosSystem {
          #   inherit specialArgs;
          #   system = "x86_64-linux";
          #   modules = defaultModules ++ [
          #     ./nixos/hosts/rickenbacker
          #   ];
          # };

          "rickenbacker" = mkNixosConfig {
            hostname = "rickenbacker";
            system = "x86_64-linux";
            hardwareModules = [
              # ./modules/hardware/phil.nix

            ];
            extraModules = [
              # ./profiles/personal.nix
            ];
          };

          "citadel" = mkNixosConfig {
            hostname = "citadel";
            system = "x86_64-linux";
            hardwareModules = [
              # ./modules/hardware/phil.nix

            ];
            extraModules = [
              # ./profiles/personal.nix
            ];
          };

          # "kclejeune@aarch64-linux" = mkNixosConfig {
          #   system = "aarch64-linux";
          #   hardwareModules = [./modules/hardware/phil.nix];
          #   extraModules = [./profiles/personal.nix];
          # };


          dns01 = nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "aarch64-linux";
            modules = defaultModules ++ [
              ./nixos/hosts/dns01
            ];
          };

          # dns02 = nixpkgs.lib.nixosSystem {
          #   inherit specialArgs;
          #   system = "aarch64-linux";
          #   modules = defaultModules ++ [
          #     ./nixos/hosts/dns02
          #   ];
          # };

          # isoimage = nixpkgs.lib.nixosSystem {
          #   system = "x86_64-linux";
          #   inherit specialArgs;
          #   modules = defaultModules ++ [
          #     "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          #     { isoImage.squashfsCompression = "gzip -Xcompression-level 1"; }
          #     ./nixos/iso
          #   ];
          # };

          # nix build .#images.rpi4
          rpi4 = nixpkgs.lib.nixosSystem {
            inherit specialArgs;

            modules = defaultModules ++ [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              ./nixos/hosts/images/sd-image
            ];
          };
          # nix build .#images.iso
          iso = nixpkgs.lib.nixosSystem {
            inherit specialArgs;

            modules = defaultModules ++ [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
              "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
              ./nixos/hosts/images/cd-dvd
            ];
          };
        };
      # simple shortcut to allow for easier referencing of correct
      # key for building images
      # > nix build .#images.rpi4
      images.rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
      images.iso = nixosConfigurations.iso.config.system.build.isoImage;

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
                path = deploy-rs.lib."${system}".activate.nixos configuration;
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
          # dns02 = mkDeployConfig "dns02.natallan.com" self.nixosConfigurations.dns02;
        };

      # deploy-rs: This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };

}
