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
      CURRENT_IMAGE=$(${pkgs.podman}/bin/podman inspect -f '{{.Image}}' $CONTAINER_NAME)

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
      ${pkgs.podman}/bin/podman pull $REGISTRY:$TAG

      # Restart the service
      echo "Restarting the container..."
      systemctl restart podman-$CONTAINER_NAME
      echo "Update and restart completed successfully."

      LATEST_VERSION=$(${pkgs.podman}/bin/podman inspect -f '{{index .Config.Labels "factorio.version"}}' $CONTAINER_NAME)
      echo "New version is $LATEST_VERSION"

      # Message to be posted in Discord
      MESSAGE="**Server Update:** $CONTAINER_NAME has been updated to version $LATEST_VERSION!"

      # Send the message using curl
      ${pkgs.curl}/bin/curl -X POST -H "Content-Type: application/json" \
          -d "{\"content\": \"$MESSAGE\"}" \
          "$DISCORD_WEBHOOK_URL"


    '';
in
{

    sops.secrets."services/${app}/env" = {
      sopsFile = ./secrets.sops.yaml;
      owner = app;
      group = app;
    };

    systemd.services.factorio-update = {
      description = "Factorio update";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target"  ];
      startAt = "hourly";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        EnvironmentFile = [ config.sops.secrets."services/factorio/env".path ];
        ExecStart = ''
          ${factorio-update}/bin/factorio-update
        '';

      };
    };
}
