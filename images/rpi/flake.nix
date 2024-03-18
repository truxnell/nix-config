{
  description = "A flake to build a basic NixOS iso";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-22.11";
  outputs =
    { self
    , nixos
    ,
    }: {
      nixosConfigurations =
        let
          exampleBase = {
            isoImage.squashfsCompression = "gzip -Xcompression-level 1";
            systemd.services.sshd.wantedBy = nixos.lib.mkForce [ "multi-user.target" ];
            users.users.root.openssh.authorizedKeys.keys = [ "<my ssh key>" ];
          };
        in
        {
          x86 = nixos.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              "${nixos}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              exampleBase
            ];
          };
          example = nixos.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ exampleBase ];
          };
        };
    };
}
