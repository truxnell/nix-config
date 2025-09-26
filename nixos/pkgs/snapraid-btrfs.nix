{
  symlinkJoin,
  writeScriptBin,
  makeWrapper,
  coreutils,
  gnugrep,
  gawk,
  gnused,
  snapraid,
  snapper,
}:
let
  name = "snapraid-btrfs";
  deps = [
    coreutils
    gnugrep
    gawk
    gnused
    snapraid
    snapper
  ];
  # snapper 11 has broken the btrfs script for now
  # patched at:
  # TODO https://github.com/automorphism88/snapraid-btrfs/issues/35
  # script =
  #   (
  #     writeScriptBin name
  #       (builtins.readFile ((fetchFromGitHub {
  #         owner = "automorphism88";
  #         repo = "snapraid-btrfs";
  #         rev = "6492a45ad55c389c0301075dcc8bc8784ef3e274";
  #         sha256 = "IQgL55SMwViOnl3R8rQ9oGsanpFOy4esENKTwl8qsgo=";
  #       })
  #       + "/snapraid-btrfs"))
  #   ).overrideAttrs (old: {
  #     buildCommand = "${old.buildCommand}\n patchShebangs $out";
  #   });
  script = (writeScriptBin name (builtins.readFile ./snapraid-btrfs.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

in
symlinkJoin {
  inherit name;
  paths = [ script ] ++ deps;
  buildInputs = [ makeWrapper ];
  postBuild = "wrapProgram $out/bin/${name} --set PATH $out/bin";
}
