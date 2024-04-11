{ pkgs
, config
, lib
, ...
}:
let
  cfg = config.myHome.shell.git;
  inherit (pkgs.stdenv) isDarwin;
in
{
  options.myHome.shell.git = {
    enable = lib.mkEnableOption "git";
    username = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.gh.enable = true;
      programs.gpg.enable = true;

      programs.git = {
        enable = true;

        userName = cfg.username;
        userEmail = cfg.email;

        extraConfig = {
          core = {
            autocrlf = "input";
          };
          init = {
            defaultBranch = "main";
          };
          pull = {
            rebase = true;
          };
          rebase = {
            autoStash = true;
          };
        };
        aliases = {
          co = "checkout";
        };
        ignores = [
          # Mac OS X hidden files
          ".DS_Store"
          # Windows files
          "Thumbs.db"
          # asdf
          ".tool-versions"
          # Sops
          ".decrypted~*"
          "*.decrypted.*"
          # Python virtualenvs
          ".venv"
        ];
        # signing = lib.mkIf (cfg.signingKey != "") {
        #   signByDefault = true;
        #   key = cfg.signingKey;
        # };
      };

      home.packages = [
        pkgs.git-filter-repo
        pkgs.tig
      ];
    })
  ];
}
