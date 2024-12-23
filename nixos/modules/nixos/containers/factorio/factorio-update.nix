{ lib
, config
, pkgs
, ...
}:
with lib;
let
  factorio-update =
    pkgs.writeShellScriptBin "factorio-update" ''
      #!/usr/bin/env bash

      # Define the container name, registry, and tag
      CONTAINER_NAME="factorio-space-age"
      REGISTRY="docker.io/factoriotools/factorio"
      TAG="stable"

      # Check if there are players playing online
      PLAYER_STATUS=$(${pkgs.podman}/bin/podman exec $CONTAINER_NAME rcon /players online)

      if [[ $PLAYER_STATUS != *"Online players (0):"* ]]; then
        echo "There are players online. Exiting."
        exit 0
      fi

      # Get the current image ID of the running container
      CURRENT_IMAGE=$(${pkgs.podman}/bin/podman inspect -f '{{.Id}}' $CONTAINER_NAME)

      # Pull the latest image from Docker Hub (or your specified registry)
      LATEST_IMAGE_ID=$(${pkgs.podman}/bin/podman pull --quiet $REGISTRY:$TAG)

      echo "Current version: $CURRENT_IMAGE"
      echo "Latest version: $LATEST_IMAGE_ID"
      # Compare the current image with the latest image
      if [[ "$CURRENT_IMAGE" == "$LATEST_IMAGE_ID" ]]; then
        echo "No new image available. Exiting."
        exit 0
      fi

      # Pull the latest image for the service
      echo "Pulling latest image..."
      podman pull $REGISTRY:$TAG

      # Restart the service
      echo "Restarting the container..."
      podman restart $CONTAINER_NAME

      echo "Update and restart completed successfully."
    '';
in
{
    systemd.services.factorio-update = {
      description = "Factorio update";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target"  ];
      startAt = "hourly";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = ''
          ${factorio-update}/bin/factorio-update
        '';
      };
    };
}
