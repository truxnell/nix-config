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
        "x86_64-linux"

      ];
    in
    rec {
      # Use nixpkgs-fmt for 'nix fmt'
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixpkgs-fmt);

      nixosModules = import ./nixos/modules/nixos;

      nixosConfigurations =
        with self.lib;
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
            , hardwareModules ? [ ]
            , baseModules ? [
                sops-nix.nixosModules.sops
                ./nixos/profiles/global.nix
                ./nixos/modules/nixos
                ./nixos/hosts/${hostname}
              ]
            , profileModules ? [ ]
            }:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = baseModules ++ hardwareModules ++ profileModules;
              specialArgs = { inherit self inputs nixpkgs; };
            };
        in
        {

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
            ];
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
        };
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
          rickenbacker = mkDeployConfig "rickenbacker" self.nixosConfigurations.rickenbacker;

          # dns02 = mkDeployConfig "dns02.natallan.com" self.nixosConfigurations.dns02;
        };

      # deploy-rs: This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      # Convenience output that aggregates the outputs for home, nixos, and darwin configurations.
      # Also used in ci to build targets generally.
      top =
        let
          nixtop = nixpkgs.lib.genAttrs
            (builtins.attrNames inputs.self.nixosConfigurations)
            (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
          # hometop = genAttrs
          #   (builtins.attrNames inputs.self.homeManagerConfigurations)
          #   (attr: inputs.self.homeManagerConfigurations.${attr}.activationPackage);
        in
        nixtop; # // hometop 
    };

}
