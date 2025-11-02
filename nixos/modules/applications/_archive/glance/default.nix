{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.mySystem.${category}.${app};
  app = "glance";
  category = "services";
  description = "homepgae";
  user = "kah"; # string
  group = "kah"; # string
  port = 8092; # int
  appFolder = "/var/lib/${app}";
  # persistentFolder = "${config.mySystem.persistentFolder}/var/lib/${appFolder}";
  host = "${app}" + (if cfg.dev then "-dev" else "");
  url = "${host}.${config.networking.domain}";
in
{
  options.mySystem.${category}.${app} = {
    enable = mkEnableOption "${app}";
    addToHomepage = mkEnableOption "Add ${app} to homepage" // {
      default = true;
    };
    monitor = mkOption {
      type = lib.types.bool;
      description = "Enable gatus monitoring";
      default = true;
    };
    prometheus = mkOption {
      type = lib.types.bool;
      description = "Enable prometheus scraping";
      default = true;
    };
    addToDNS = mkOption {
      type = lib.types.bool;
      description = "Add to DNS list";
      default = true;
    };
    dev = mkOption {
      type = lib.types.bool;
      description = "Development instance";
      default = false;
    };
    backup = mkOption {
      type = lib.types.bool;
      description = "Enable backups";
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
    # "d ${appFolder}/ 0750 ${user} ${group} -"
    # ];

    # environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
    #   directories = [{ directory = appFolder; inherit user; inherit group; mode = "750"; }];
    # };

    ## service
    services.glance = {
      enable = true;
      settings = {
        server = {
          openFirewall = true;
          inherit port;
        };
        pages = [
          {
            hide-desktop-navigation = true;
            columns = [
              {
                size = "small";
                widgets = [
                  {
                    type = "clock";
                    hour-format = "24h";
                  }

                  # {
                  #   type = "dns-stats";
                  #   service = "adguard";
                  #   url = "https://adguard.hadi.diy";
                  #   username = "hadi";
                  #   # password = "\${secret:adguard-pwd}";
                  # }

                  {
                    type = "twitch-channels";
                    channels = [
                      "djcquence"
                      "jonathanong"
                      "dj_johnny_rico"
                      "baylightbrew"
                      "Trance_Alliance"
                      "tkkttony"
                      "Liquid_Bongo"
                      "GamesDoneQuick"
                      "Sekhali"
                    ];
                  }
                ];
              }
              {
                size = "full";
                widgets = [
                  {
                    type = "search";
                    search-engine = "kagi";
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        title = "";
                        same-tab = true;
                        color = "200 50 50";
                        links = [
                          {
                            title = "ProtonMail";
                            url = "https://proton.me/mail";
                          }
                          {
                            title = "Github";
                            url = "https://github.com";
                          }
                          {
                            title = "Youtube";
                            url = "https://youtube.com";
                          }
                          {
                            title = "Figma";
                            url = "https://figma.com";
                          }
                        ];
                      }
                      {
                        title = "Docs";
                        same-tab = true;
                        color = "200 50 50";
                        links = [
                          {
                            title = "Nixpkgs repo";
                            url = "https://github.com/NixOS/nixpkgs";
                          }
                          {
                            title = "Nixvim";
                            url = "https://nix-community.github.io/nixvim/";
                          }
                          {
                            title = "Hyprland wiki";
                            url = "https://wiki.hyprland.org/";
                          }
                          {
                            title = "Search NixOS";
                            url = "https://search-nixos.hadi.diy";
                          }
                        ];
                      }
                      {
                        title = "Homelab";
                        same-tab = true;
                        color = "100 50 50";
                        links = [
                          {
                            title = "Router";
                            url = "http://192.168.1.254/";
                          }
                          {
                            title = "Cloudflare";
                            url = "https://dash.cloudflare.com/";
                          }
                        ];
                      }
                      {
                        title = "Work";
                        same-tab = true;
                        color = "50 50 50";
                        links = [
                          {
                            title = "Outlook";
                            url = "https://outlook.office.com/";
                          }
                          {
                            title = "Teams";
                            url = "https://teams.microsoft.com/";
                          }
                          {
                            title = "Office";
                            url = "https://www.office.com/";
                          }
                        ];
                      }
                      {
                        title = "Cyber";
                        same-tab = true;
                        # color = rgb-to-hsl "base09";
                        links = [
                          {
                            title = "CyberChef";
                            url = "https://cyberchef.org/";
                          }
                          {
                            title = "TryHackMe";
                            url = "https://tryhackme.com/";
                          }
                          {
                            title = "RootMe";
                            url = "https://www.root-me.org/";
                          }
                          {
                            title = "Exploit-DB";
                            url = "https://www.exploit-db.com/";
                          }
                          {
                            title = "CrackStation";
                            url = "https://crackstation.net/";
                          }
                        ];
                      }
                      {
                        title = "Misc";
                        same-tab = true;
                        # color = rgb-to-hsl "base01";
                        links = [
                          {
                            title = "Svgl";
                            url = "https://svgl.app/";
                          }
                          {
                            title = "Excalidraw";
                            url = "https://excalidraw.com/";
                          }
                          {
                            title = "Cobalt (Downloader)";
                            url = "https://cobalt.tools/";
                          }
                          {
                            title = "Mazanoke (Image optimizer)";
                            url = "https://mazanoke.com/";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                        name = "Daedalus";
                        hide-swap = true;
                        hide-mountpoints-by-default = true;
                        mountpoints = {
                          "/zfs/documents".hide = false;
                          "/tank".hide = false;
                          "/".hide = false;

                        };

                      }
                    ];
                  }
                  {
                    type = "split-column";
                    widgets = [
                      {
                        type = "hacker-news";
                        collapse-after = 6;
                      }
                      {
                        type = "lobsters";
                        collapse-after = 6;
                      }
                    ];
                  }
                  {
                    type = "group";
                    widgets = [
                      {
                        type = "monitor";
                        title = "Services";
                        cache = "1m";
                        sites = [
                          {
                            title = "Vaultwarden";
                            url = "https://vault.trux.dev";
                            icon = "si:bitwarden";
                          }
                        ];
                      }
                      {
                        type = "monitor";
                        title = "*arr";
                        cache = "1m";
                        sites = [
                          {
                            title = "Jellyfin";
                            url = "https://jellyfin.trux.dev";
                            icon = "si:jellyfin";
                          }
                          {
                            title = "Jellyseerr";
                            url = "https://jellyseer.trux.dev/";
                            icon = "si:odysee";
                          }
                          {
                            title = "Radarr";
                            url = "https://radarr.trux.dev";
                            icon = "si:radarr";
                          }
                          {
                            title = "Sonarr";
                            url = "https://sonarr.trux.dev";
                            icon = "si:sonarr";
                          }
                          {
                            title = "Lidarr";
                            url = "https://lidarr.trux.dev";
                            icon = "si:lidarr";
                          }
                          {
                            title = "Readarr";
                            url = "https://readarr.trux.dev";
                            icon = "si:readarr";
                          }
                          {
                            title = "Prowlarr";
                            url = "https://prowlarr.trux.dev";
                            icon = "si:podcastindex";
                          }
                          {
                            title = "Qbittorrent";
                            url = "https://qbittorrent.trux.dev";
                            icon = "si:qbittorrent";
                          }
                          {
                            title = "Qbittorrent-lts";
                            url = "https://qbittorrent-lts.trux.dev";
                            icon = "si:qbittorrent";
                          }

                        ];
                      }
                    ];
                  }
                ];
              }
              {
                size = "small";
                widgets = [
                  {
                    type = "weather";
                    units = "metric";
                    location = "Melbourne, Australia";
                  }
                  {
                    type = "repository";
                    repository = "truxnell/nix-config";
                    pull-reqeusts-limit = 5;
                    commits-limit = 3;
                    issues-limit = 0;
                  }
                  {
                    type = "custom-api";
                    title = "Random Fact";
                    cache = "6h";
                    url = "https://uselessfacts.jsph.pl/api/v2/facts/random";
                    template = ''
                      <p class="size-h4 color-paragraph">{{ .JSON.String "text" }}</p>
                    '';

                  }
                  {
                    type = "markets";
                    markets = [
                      {
                        symbol = "BTC-USD";
                        name = "Bitcoin";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:BTCUSD";
                      }
                      {
                        symbol = "ETH-USD";
                        name = "Ethereum";
                        chart-link = "https://www.tradingview.com/chart/?symbol=INDEX:ETHUSD";
                      }
                      {
                        symbol = "DOGE-USD";
                        name = "DOGE";
                        chart-link = "https://finance.yahoo.com/quote/DOGE-USD/";
                      }
                      {
                        symbol = "AUDUSD=X";
                        name = "AUD/USD";
                        chart-link = "https://finance.yahoo.com/quote/AUDUS/";
                      }

                    ];
                  }

                ];
              }
            ];
            name = "Home";
          }
        ];

      };

    };

    ### gatus integration
    mySystem.services.gatus.monitors = mkIf cfg.monitor [
      {
        name = app;
        group = "${category}";
        url = "https://${url}";
        interval = "1m";
        conditions = [
          "[CONNECTED] == true"
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 50"
        ];
      }
    ];

    ### Ingress
    services.nginx.virtualHosts.${url} = {
      forceSSL = true;
      useACMEHost = config.networking.domain;
      locations."^~ /" = {
        proxyPass = "http://127.0.0.1:${builtins.toString port}";
        extraConfig = "resolver 10.88.0.1;";
      };
    };

    ### firewall config

    # networking.firewall = mkIf cfg.openFirewall {
    #   allowedTCPPorts = [ port ];
    #   allowedUDPPorts = [ port ];
    # };

    ### backups
    warnings = [
      (mkIf (
        !cfg.backup && config.mySystem.purpose != "Development"
      ) "WARNING: Backups for ${app} are disabled!")
    ];

    services.restic.backups = mkIf cfg.backup (
      config.lib.mySystem.mkRestic {
        inherit app user;
        paths = [ appFolder ];
        inherit appFolder;
      }
    );

    # services.postgresqlBackup = {
    #   databases = [ app ];
    # };

  };
}
