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

  firstOrDefault = first: default: if !isNull first then first else default;

  existsOrDefault = x: set: default: if hasAttr x set then getAttr x set else default;

  mkIfElse = p: yes: no: mkMerge [
    (mkIf p yes)
    (mkIf (!p) no)
  ];
}
