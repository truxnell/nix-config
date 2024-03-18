{ inputs
, outputs
, config
, ...
}: {
  # Time
  networking.timeServers = [ "10.8.10.1" ];
  services.chrony = {
    enable = true;
  };
}
