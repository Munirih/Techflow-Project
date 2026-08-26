#!/bin/bash

set -u

HOST="localhost"
MAX_RETRIES=5
for i in $(seq 1 "$MAX_RETRIES"); do
    echo "Attempt $i/$MAX_RETRIES: Checking health at http://$HOST:5000/health"

    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$HOST:5000/health)
    if [ "$STATUS" -eq 200 ]; then
        echo "Health check passed. Application is running."
        exit 0
    fi
    echo "Health check failed with status code $STATUS. Retrying in 5 seconds..."
    sleep 5
done
echo "Failed health check after $MAX_RETRIES attempts."
exit 1



