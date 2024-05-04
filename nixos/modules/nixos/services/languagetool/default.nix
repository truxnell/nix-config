{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "%{app}";
  category = "%{cat}";
  description = "%{description}";
  image = "%{image}";
  user = "%{user kah}"; #string
  group = "%{group kah}"; #string
  port = %{ port }; #int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host="${app}" ++ mkIf cfg.development "-dev";
  url = "${host}.${config.networking.domain}";
  in
  {
  options.mySystem.${category}.${app} =
  {
  enable = mkEnableOption "${app}";
  addToHomepage = mkEnableOption "Add ${app} to homepage" // { default = true; };
  monitor = mkOption
  {
  type = lib.types.bool;
  description = "Enable gatus monitoring";
  default = true;
  };
  prometheus = mkOption
  {
  type = lib.types.bool;
  description = "Enable prometheus scraping";
  default = true;
  };
  addToDNS = mkOption
  {
  type = lib.types.bool;
  description = "Add to DNS list";
  default = true;
  };
  development = mkOption
  {
  type = lib.types.bool;
  description = "Development instance";
  default = false;
  };
  backupLocal = mkOption
  {
  type = lib.types.bool;
  description = "Enable local backups";
  default = true;
  };
  backupRemote = mkOption
  {
  type = lib.types.bool;
  description = "Enable remote backups";
  default = true;
  };


  };

  config = mkIf cfg.enable {

  ## Secrets
  # sops.secrets."${category}/${app}/env" = {
  #   sopsFile = ./secrets.sops.yaml;
  #   owner = user;
  #   group = group;
  #   restartUnits = [ "${app}.service" ];
  # };

  users.users.truxnell.extraGroups = [ group ];


  # Folder perms - only for containers
  # systemd.tmpfiles.rules = [
  # "d ${persistentFolder}/ 0750 ${user} ${group} -"
  # ];

  ## service
  # services.test= {
  #   enable = true;
  # };

  # homepage integration
  mySystem.services.homepage.infrastructure = mkIf cfg.addToHomepage [
  {
  ${app} = {
  icon = "${app}.svg";
  href = "https://${url}";
  description = description;
  };
  }
  ];

  ### gatus integration
  mySystem.services.gatus.monitors = mkIf cfg.monitor [
  {
  name = app;
  group = "${category}";
  url = "https://${url}";
  interval = "1m";
  conditions = [ "[CONNECTED] == true" "[STATUS] == 200" "[RESPONSE_TIME] < 50" ];
  }
  ];

  ### Ingress
  services.nginx.virtualHosts.${url} = {
  useACMEHost = host;
  forceSSL = true;
  locations."^~ /" = {
  proxyPass = "http://127.0.0.1:${builtins.toString port}";
  };
  };

  ### firewall config

  # networking.firewall = mkIf cfg.openFirewall {
  #   allowedTCPPorts = [ port ];
  #   allowedUDPPorts = [ port ];
  # };

  ### backups
  warnings = [
  (mkIf (!cfg.backupLocal && config.mySystem.purpose != "Development")
  "WARNING: Local backups for ${app} are disabled!")
  (mkIf (!cfg.backupRemote && config.mySystem.purpose != "Development")
  "WARNING: Remote backups for ${app} are disabled!")
  ];

  services.restic.backups = mkIf cfg.backups config.lib.mySystem.mkRestic
  {
  inherit app user;
  paths = [ appFolder ];
  inherit appFolder;
  local=cfg.backupLocal;
  remote=cfg.backupRemote;
  };


  };
  }
