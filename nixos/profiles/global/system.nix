{ config, lib, pkgs, ... }:
with lib;
{
  system = {
    # Enable printing changes on nix build etc with nvd
    activationScripts.report-changes = ''
      PATH=$PATH:${lib.makeBinPath [ pkgs.nvd pkgs.nix ]}
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '';

    # Do not change unless you know what you are doing
    stateVersion = "23.11"; # THERE BE DRAGONS

    #      (This one comes in the niiiiight)           :::
    #                                              :: :::.
    #                        \/,                    .:::::
    #            \),          \`-._                 :::888
    #            /\            \   `-.             ::88888
    #           /  \            | .(                ::88
    #          /,.  \           ; ( `              .:8888
    #             ), \         / ;``               :::888
    #            /_   \     __/_(_                  :88
    #              `. ,`..-'      `-._    \  /      :8
    #                )__ `.           `._ .\/.
    #               /   `. `             `-._______m         _,
    #   ,-=====-.-;'                 ,  ___________/ _,-_,'"`/__,-.
    #  C   =--   ;                   `.`._    V V V       -=-'"#==-._
    # :,  \     ,|      UuUu _,......__   `-.__A_A_ -. ._ ,--._ ",`` `-
    # ||  |`---' :    uUuUu,'          `'--...____/   `" `".   `
    # |`  :       \   UuUu:
    # :  /         \   UuUu`-._
    #  \(_          `._  uUuUu `-.
    #  (_3             `._  uUu   `._
    #                     ``-._      `.
    #                          `-._    `.
    #                              `.    \
    #                                )   ;
    #                               /   /
    #                `.        |\ ,'   /
    #                  ",_A_/\-| `   ,'
    #                    `--..,_|_,-'\
    #                           |     \
    #                           |      \__
    #                           |__

  };
}
