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
    # TODO Move
    nixpkgs-fmt
    nil
    gh
  ];
   
  programs.mtr.enable = true;
}
