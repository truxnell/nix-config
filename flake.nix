{
  description = "My nixos homelab";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Core tools
    colmena.url = "github:zhaofengli/colmena";
    cachix.url = "github:cachix/cachix";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-inspect.url = "github:bluskript/nix-inspect";

    # deploy-rs for remote deployment
    deploy-rs.url = "github:serokell/deploy-rs";

    # Nixpkgs-following inputs
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      impermanence,
      deploy-rs,
      ...
    }@inputs:

    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];

    in
    rec {
      # Use nixfmt-tree for 'nix fmt' (official formatter from https://github.com/NixOS/nixfmt)
      formatter = forAllSystems (system: nixpkgs.legacyPackages."${system}".nixfmt-tree);

      # Development shell with essential tools
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
          python-with-packages = pkgs.python3.withPackages (ps: with ps; [
            mkdocs-material
            mkdocs-minify
            pygments
          ]);
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Essential CLI tools
              just
              git
              nix
              sops
              statix
              nixfmt-rfc-style
              nil
              
              # Development & linting
              pre-commit
              deadnix
              
              # Deployment & operations
              deploy-rs.packages."${system}".default
              nvd
              
              # Documentation
              python-with-packages
              mkdocs
            ];
          };
          
          # Fly.io Vaultwarden deployment shell
          flyio-vaultwarden = pkgs.mkShell {
            buildInputs = with pkgs; [
              flyctl
              doppler
              go-task
            ];
          };
        });

      # extend lib with my custom functions
      lib = nixpkgs.lib.extend (
        final: _prev: {
          inherit inputs;
          myLib = import ./nixos/lib {
            inherit inputs;
            lib = final;
          };
        }
      );

      nixosConfigurations =
        with self.lib;
        let
          specialArgs = {
            inherit inputs outputs;
          };
          overlays = import ./nixos/overlays { inherit inputs; };

          mkNixosConfig =
            {
              hostname,
              system ? "x86_64-linux",
              nixpkgs ? inputs.nixpkgs,
              hardwareModules ? [ ],
              baseModules ? [
                sops-nix.nixosModules.sops
                impermanence.nixosModules.impermanence
                ./nixos/profiles/global.nix
                ./nixos/modules/nixos
                ./nixos/hosts/${hostname}
              ],
              profileModules ? [ ],
            }:
            nixpkgs.lib.nixosSystem {
              inherit system lib;
              modules = baseModules ++ hardwareModules ++ profileModules;
              specialArgs = { inherit self inputs nixpkgs; };
              pkgs = import nixpkgs {
                inherit system;
                overlays = builtins.attrValues overlays;
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = _: true;
                  permittedInsecurePackages = [
                    "aspnetcore-runtime-6.0.36"
                    "aspnetcore-runtime-wrapped-6.0.36"
                    "dotnet-sdk-6.0.428"
                    "dotnet-sdk-wrapped-6.0.428"
                  ];
                };
              };
            };
        in
        rec {
          "daedalus" = mkNixosConfig {
            hostname = "daedalus";
            system = "x86_64-linux";
            profileModules = [ ./nixos/profiles/role-server.nix ];
          };

          "shodan" = mkNixosConfig {
            hostname = "shodan";
            system = "x86_64-linux";
            profileModules = [
              ./nixos/profiles/role-server.nix
              ./nixos/profiles/role-dev.nix
            ];
          };
        };

    };
}
