{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.deploy;
in
{
  options.mySystem.deploy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable deploy user for deploy-rs";
      default = false;
    };
  };

  config = mkIf cfg.enable {
    users.users.deploy = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZS9J1ydflZ4iJdJgO8+vnN8nNSlEwyn9tbWU9OcysW truxnell@home"
      ];
    };

    security.sudo = {
      extraRules = [
        {
          users = [ "deploy" ];
          commands = [
            {
              command = "/run/current-system/bin/switch-to-configuration";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      extraConfig = ''
        # Deploy user passwordless sudo for deploy-rs commands
        deploy ALL=(ALL) NOPASSWD: /nix/var/nix/profiles/system/bin/activate-rs activate *
        deploy ALL=(ALL) NOPASSWD: /nix/var/nix/profiles/system/bin/activate-rs wait *
        deploy ALL=(ALL) NOPASSWD: /nix/store/*/bin/activate-rs activate *
        deploy ALL=(ALL) NOPASSWD: /nix/store/*/bin/activate-rs wait *
        deploy ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/rm /tmp/deploy-rs*
      '';
    };
  };
}

