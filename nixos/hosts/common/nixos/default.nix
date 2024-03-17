{
  inputs,
  outputs,
  config,
  sops-nix,
  ...
}: {
  imports =
    [
      # inputs.home-manager.nixosModules.home-manager
      #inputs.sops-nix.nixosModules.sops
      ./locale.nix
      ./nix.nix
      ./openssh.nix
      ./packages.nix
    ]
    ++ (builtins.attrValues {});

  # home-manager.extraSpecialArgs = { inherit inputs outputs; }; TODO Home-manager

  nixpkgs = {
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # TODO Shared sops location
  # sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  # sops.secrets.msmtp = {
  #   sopsFile = ./secret.sops.yaml;
  # }

  # # TODO Email settings
  # programs.msmtp = {
  #   enable = true;
  #   accounts.default = {
  #     host = "smtp-relay.mcbadass.local";
  #     from = "${config.networking.hostName}@trux.dev";
  #   };
  #   defaults = {
  #     aliases = "/etc/aliases";
  #   };
  # };

  environment.etc = {
    "aliases" = {
      text = ''
        root: ${config.networking.hostName}@trux.dev
      '';
      mode = "0644";
    };
  };
}
