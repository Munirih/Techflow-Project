#!/bin/bash

set -u 

CONTAINER_NAME="techflow-app"
PORT=5000

docker pull "${IMAGE_NAME}:previous_stable"
docker ps -q -f name="$CONTAINER_NAME"
docker stop "$CONTAINER_NAME" 2>/dev/null
docker rm "$CONTAINER_NAME" 2>/dev/null
docker run -d --name "$CONTAINER_NAME" -p "$PORT":"$PORT" "${IMAGE_NAME}:previous_stable"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health)
if [ $STATUS -eq 200 ]; then
    echo "Rollback Successed"
else
    echo "Rollback Failed"
    exit 1
fi
