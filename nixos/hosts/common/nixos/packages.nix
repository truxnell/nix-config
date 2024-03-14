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
  ];
   
  programs.mtr.enable = true;
}
