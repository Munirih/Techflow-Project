#!/bin/bash

set -u

CONTAINER_NAME="techflow-app"
RUNNING_CONTAINER=$(docker ps -q -f name="$CONTAINER_NAME")

if [ -z "$RUNNING_CONTAINER" ]; then
    echo "No running container named ${CONTAINER_NAME}"
    exit 0
fi

CURRENT_IMAGE=$(docker inspect --format='{{.Image}}' "$CONTAINER_NAME")

if [ -z "$CURRENT_IMAGE" ]; then
    echo "ERROR: Could not determine image for running container '$CONTAINER_NAME'."
    exit 1
fi

docker tag "$CURRENT_IMAGE" "${IMAGE_NAME}:previous_stable"
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

if docker push "${IMAGE_NAME}:previous_stable"; then
    echo "Successfully pushed previous stable image to DockerHub."
    exit 0
else
    echo "Failed to push previous stable image to DockerHub."
    exit 1
fi