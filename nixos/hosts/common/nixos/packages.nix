{ config, pkgs, lib, ... }:
{
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

    # TODO Move
    nixpkgs-fmt
    nil
    gh
    sops
  ];

  programs.mtr.enable = true;
}
