{
  lib,
  stdenv,
  fetchzip,
  gettext,
}:

stdenv.mkDerivation rec {
  pname = "cockpit-podman";
  version = "99";

  src = fetchzip {
    url = "https://github.com/cockpit-project/${pname}/releases/download/${version}/${pname}-${version}.tar.xz";
    sha256 = "140sjw0pmzxs2hm33hrrragyhqq5gfp7n5ypma4bm6mnnnx0dydd";
  };

  nativeBuildInputs = [
    gettext
  ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace /usr/share $out/share
    touch pkg/lib/cockpit-po-plugin.js
    touch dist/manifest.json
  '';

  dontBuild = true;

  postFixup = ''
    substituteInPlace $out/share/cockpit/podman/manifest.json \
      --replace-warn "/lib/systemd/system/podman.socket" "/run/podman/podman.sock"
  '';

  meta = with lib; {
    description = "Cockpit UI for podman containers";
    license = licenses.lgpl21;
    homepage = "https://github.com/cockpit-project/cockpit-podman";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
