{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.users.truxnell = {
    isNormalUser = true;
    shell = pkgs.fish;
    # passwordFile = config.sops.secrets.taylor-password.path;
    # initialHashedPassword = ""; # TODO add key
    extraGroups =
      [
        "wheel"
      ]
      ++ ifTheyExist [
        "network"
        "samba-users"
      ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZS9J1ydflZ4iJdJgO8+vnN8nNSlEwyn9tbWU9OcysW truxnell@home"
    ];

    packages = [pkgs.home-manager];
  };

  # home-manager.users.taylor = import ../../../../../home-manager/taylor_${config.networking.hostName}.nix; TODO home-manager?
}
