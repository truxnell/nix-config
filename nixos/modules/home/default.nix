{ inputs
, config
, ...
}: {
  imports = [
    ./shell
  ];

  # Home-manager defaults
  config = {
    home.stateVersion = "23.11";

    programs = {
      home-manager.enable = true;
      git.enable = true;
    };

    xdg.enable = true;
  };
}
