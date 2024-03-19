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

      nixosConfigurations =
        let
          defaultModules =
            # (builtins.attrValues nixosModules) ++
            [
              sops-nix.nixosModules.sops
            ];
          specialArgs = {
            inherit inputs outputs;
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

          dns01 = nixpkgs.lib.nixosSystem {
            inherit specialArgs;
            system = "aarch64-linux";
            modules = defaultModules ++ [
              ./nixos/hosts/dns01
            ];
          };

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
        };
      images.rpi4 = nixosConfigurations.rpi4.config.system.build.sdImage;
    };

}
