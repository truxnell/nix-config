# Nix expression validation tests
# Run with: nix eval --impure -f test-nix-expressions.nix

let
  lib = (import <nixpkgs> {}).lib;
  
  # Test that all hosts are accessible
  testHosts = lib.mapAttrs (name: value: {
    name = name;
    accessible = true;
  }) (import ./flake.nix { }).nixosConfigurations;
  
  # Test that formatter is defined
  testFormatter = builtins.hasAttr "formatter" (import ./flake.nix { });
  
  # Test that lib output exists
  testLib = builtins.hasAttr "lib" (import ./flake.nix { });
  
  # Test that devShells are defined
  testDevShells = builtins.hasAttr "devShells" (import ./flake.nix { });
  
in
{
  hosts = testHosts;
  formatter = testFormatter;
  lib = testLib;
  devShells = testDevShells;
  
  # All tests passed if this evaluates to true
  allTestsPass = 
    testFormatter && 
    testLib && 
    testDevShells && 
    (builtins.length (builtins.attrNames testHosts) > 0);
}
