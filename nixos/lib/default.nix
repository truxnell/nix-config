{ inputs, ... }:
with inputs.nixpkgs.lib;
let
  strToPath = x: path:
    if builtins.typeOf x == "string"
    then builtins.toPath ("${toString path}/${x}")
    else x;
  strToFile = x: path:
    if builtins.typeOf x == "string"
    then builtins.toPath ("${toString path}/${x}.nix")
    else x;
in
rec {

  # main service builder
  lib.myLib.mkService = options: (
    let
      # user = if builtins.hasAttr "user" options then options.user else 568;
      # group = if builtins.hasAttr "group" options then options.group else 568;
      a = 1;
    in
    {
      # virtualisation.oci-containers.containers.${options.app} = {
      #   image = "${options.image}";
      #   user = "${user}:${group}";
      #   environment = {
      #     TZ = config.time.timeZone;
      #   } ++ container.env;
      #   environmentFiles = [ ] ++ container.envFiles;
      #   volumes = [
      #     "/etc/localtime:/etc/localtime:ro"
      #     "${configFile}:/config/config.yaml:ro"
      #   ];

      #   labels = config.lib.myLib.mkTraefikLabels {
      #     name = options.app;
      #     inherit port;
      #   };

      #   # extraOptions = [ "--cap-add=NET_RAW" ]; # Required for ping/etc to do monitoring
      # };
    }
  );

}
