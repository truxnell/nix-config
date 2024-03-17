{
  config,
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    bat
    jq
    yq
    btop
    neovim
    vim
    git
    dnsutils
    nvd
    gh

    # TODO Move
  ];
  programs.direnv = {
    # TODO move to home-manager
    enable = true;
    nix-direnv.enable = true;
  };
  programs.mtr.enable = true;
}
