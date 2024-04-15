{ lib
, config
, pkgs

, ...
}:

with lib;
let
  cfg = config.mySystem.editor.vscodium;
in
{
  options.mySystem.editor.vscodium.enable = mkEnableOption "Vscodium";

  config = mkIf cfg.enable {

    # TODO add USER settings.json
    # Enable vscode & addons
    environment.systemPackages = with pkgs; [
      (vscode-with-extensions.override {
        vscode = vscodium;
        vscodeExtensions = with vscode-extensions;
          [
            bbenoist.nix
            mkhl.direnv
            streetsidesoftware.code-spell-checker
            oderwat.indent-rainbow

          ]
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "prettier-vscode";
              publisher = "esbenp";
              version = "10.1.0";
              sha256 = "01s0vi2h917mqfpdrhqhp2ijwkibw95yk2js0l587wvajbbry2s9";
            }

            {
              name = "vscode-docker";
              publisher = "ms-azuretools";
              version = "1.28.0";
              sha256 = "0nmc3pdgxpmr6k2ksdczkv9bbwszncfczik0xjympqnd2k0ra9h0";
            }

            {
              name = "gitlens";
              publisher = "eamodio";
              version = "14.7.0";
              sha256 = "07f9fryaci8lsrdahgll5yhlzf5rhscpy1zd258hi211ymvkxlmy";
            }

            {
              name = "remote-containers";
              publisher = "ms-vscode-remote";
              version = "0.327.0";
              sha256 = "0asswm55bx5gpz08cgpmgfvnb0494irj0gsvzx5nwknqfzpj07lz";
            }

            {
              name = "remote-ssh";
              publisher = "ms-vscode-remote";
              version = "0.107.1";
              sha256 = "1q9xp8id9afhjx67zc7a61zb572f296apvdz305xd5v4brqd9xrf";
            }

            {
              name = "vscode-yaml";
              publisher = "redhat";
              version = "1.14.0";
              sha256 = "0pww9qndd2vsizsibjsvscz9fbfx8srrj67x4vhmwr581q674944";
            }

            {
              name = "todo-tree";
              publisher = "gruntfuggly";
              version = "0.0.226";
              sha256 = "0yrc9qbdk7zznd823bqs1g6n2i5xrda0f9a7349kknj9wp1mqgqn";
            }

            {
              name = "path-autocomplete";
              publisher = "ionutvmi";
              version = "1.25.0";
              sha256 = "0jjqh3p456p1aafw1gl6xgxw4cqqzs3hssr74mdsmh77bjizcgcb";
            }

            {
              name = "even-better-toml";
              publisher = "tamasfe";
              version = "0.19.2";
              sha256 = "0q9z98i446cc8bw1h1mvrddn3dnpnm2gwmzwv2s3fxdni2ggma14";
            }

            {
              name = "linter";
              publisher = "fnando";
              version = "0.0.19";
              sha256 = "13bllbxd7sy4qlclh37qvvnjp1v13al11nskcf2a8pmnmj455v4g";
            }

            {
              name = "catppuccin-vsc";
              publisher = "catppuccin";
              version = "3.11.0";
              sha256 = "12bzx1pv9pxbm08dhvl8pskpz1vg2whxmasl0qk2x54swa2rhi4d";
            }

            {
              name = "catppuccin-vsc-icons";
              publisher = "catppuccin";
              version = "1.8.0";
              sha256 = "12sw9f00vnmppmvhwbamyjcap3acjs1f67mdmyv6ka52mav58z8z";
            }

            {
              name = "nix-ide";
              publisher = "jnoortheen";
              version = "0.2.2";
              sha256 = "1264027sjh9a112si0y0p3pk3y36shj5b4qkpsj207z7lbxqq0wg";
            }

            {
              name = "vscode-swissknife";
              publisher = "luisfontes19";
              version = "1.8.1";
              sha256 = "1rpk8zayzkn2kg4jjdd2fy6xl50kib71dqg73v46326cr4dwxa7c";
            }

            {
              name = "pre-commit-helper";
              publisher = "elagil";
              version = "0.5.0";
              sha256 = "05cs1ndnha9dgv1ys23z81ajk300wpixqmks0lfmrj1zwyjg2wlj";
            }

            {
              name = "sops-edit";
              publisher = "shipitsmarter";
              version = "1.0.0";
              sha256 = "0b2z9khiwrpf6gxdb9y315ayqkibvgixmvx82in5rlp8pndb6sq4";
            }

            {
              name = "json5-for-vscode";
              publisher = "tudoudou";
              version = "0.0.3";
              sha256 = "1d1c18mr91ll5fsp0l0aszyi7nx0ad352ssm0fm40z81m4dmzm0w";
            }
          ];
      })
    ];

  };


}
