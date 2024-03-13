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
  ];

  programs.mtr.enable = true;
}
