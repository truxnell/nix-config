{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.nginx;
in
{
  options.mySystem.services.nginx.enable = mkEnableOption "nginx";

  config = mkIf cfg.enable {

     services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedBrotliSettings=true;
    recommendedHttpHeaders = true;

    statusPage = true;
    enableReload = true;
    
    appendHttpConfig = ''';

    # fetch cloudflare ip's from cloudflare
    # for cloudflare realip
    commonHttpConfig = ''
        ${concatMapStrings (ip: "set_real_ip_from ${ip};\n")
          (filter (line: line != "")
            (splitString "\n" ''
              ${readFile (fetchurl "https://www.cloudflare.com/ips-v4/")}
              ${readFile (fetchurl "https://www.cloudflare.com/ips-v6/")}
            ''))}
        real_ip_header CF-Connecting-IP;
        add_header X-Clacks-Overhead "GNU Terry Pratchett";
      '';

  };
}
