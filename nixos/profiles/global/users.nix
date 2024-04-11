{ pkgs
, config
, ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{

  sops.secrets = {
    truxnell-password = {
      sopsFile = ./secret.sops.yaml;
      neededForUsers = true;
    };
  };

  users.users.truxnell = {
    isNormalUser = true;
    shell = pkgs.fish;
    passwordFile = config.sops.secrets.truxnell-password.path;
    extraGroups =
      [
        "wheel"
      ]
      ++ ifTheyExist [
        "network"
        "samba-users"
        "docker"
        "audio" # pulseaudio
      ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZS9J1ydflZ4iJdJgO8+vnN8nNSlEwyn9tbWU9OcysW truxnell@home"
    ]; # TODO do i move to ingest github creds?

    # packages = [ pkgs.home-manager ];
  };

}
