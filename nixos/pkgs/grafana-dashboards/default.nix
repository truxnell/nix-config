{ pkgs }:

with pkgs;

let
  inherit (pkgs) stdenv fetchurl;
in

lib.makeScope pkgs.newScope (_self:
let
  buildGrafanaDashboard = args: stdenv.mkDerivation (args // {
    pname = "grafana-dashboard-${args.pname}-${toString args.id}";
    inherit (args) version;
    src = fetchurl {
      url = "https://grafana.com/api/dashboards/${toString args.id}/revisions/${args.version}/download";
      inherit (args) hash;
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp $src $out/${args.pname}-${toString args.id}.json
      runHook postInstall
    '';
  });
in
{
  inherit buildGrafanaDashboard;

  node-exporter = buildGrafanaDashboard {
    id = 1860;
    pname = "node-exporter-full";
    version = "31";
    hash = "sha256-QsRHsnayYRRGc+2MfhaKGYpNdH02PesnR5b50MDzHIg=";
  };
  node-systemd = (buildGrafanaDashboard {
    id = 1617;
    pname = "node-systemd";
    version = "1";
    hash = "sha256-MEWU5rIqlbaGu3elqdSoMZfbk67WDnH0VWuC8FqZ8v8=";
  }).overrideAttrs (_: {
    src = ./node-systemd.json; # sadly only imported dashboards work
  });

  nginx = buildGrafanaDashboard {
    id = 12708;
    pname = "nginx";
    version = "1";
    hash = "sha256-T1HqWbwt+i/We+Y2B7hcl3CijGxZF5QI38aPcXjk9y0=";
  };

})
