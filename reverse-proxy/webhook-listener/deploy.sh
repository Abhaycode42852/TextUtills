#!/bin/sh
# deploy.sh
# Same blue-green logic as deploy.ps1, translated to shell so it can run
# inside the (Linux) webhook listener container. This also means it'll
# work unmodified later on the Raspberry Pi.
set -e

IMAGE="${DOCKERHUB_USERNAME}/textutills:latest"
NETWORK="textutills-net"
PROXY_CONTAINER="textutills-proxy"
ACTIVE_CONTAINER="textutills-active"
NEW_CONTAINER="textutills-new"

echo "== Checking for a new image =="

# Image ID currently backing the running "active" container
CURRENT_IMAGE_ID=$(docker inspect --format='{{.Image}}' "$ACTIVE_CONTAINER")

# Pull whatever "latest" points to right now
docker pull "$IMAGE" > /dev/null

LATEST_IMAGE_ID=$(docker inspect --format='{{.Id}}' "$IMAGE")

if [ "$CURRENT_IMAGE_ID" = "$LATEST_IMAGE_ID" ]; then
    echo "No new image found. Nothing to do."
    exit 0
fi

echo "New image detected. Starting new container: $NEW_CONTAINER"

# Clean up any leftover from a previous failed attempt
docker rm -f "$NEW_CONTAINER" 2>/dev/null || true

docker run -d \
  --name "$NEW_CONTAINER" \
  --network "$NETWORK" \
  --restart unless-stopped \
  "$IMAGE" > /dev/null

echo "== Health-checking the new container =="

HEALTHY=0
for i in 1 2 3 4 5; do
    sleep 2
    if docker exec "$PROXY_CONTAINER" wget -qO- "http://${NEW_CONTAINER}:80" > /dev/null 2>&1; then
        HEALTHY=1
        break
    fi
    echo "Attempt $i not healthy yet, retrying..."
done

if [ "$HEALTHY" -ne 1 ]; then
    echo "New container failed health check. Rolling back - old container untouched."
    docker rm -f "$NEW_CONTAINER"
    exit 1
fi

echo "== Healthy. Swapping into place =="

docker rename "$ACTIVE_CONTAINER" textutills-old
docker rename "$NEW_CONTAINER" "$ACTIVE_CONTAINER"

# Force Nginx to re-resolve the name and pick up the new container's IP
docker exec "$PROXY_CONTAINER" nginx -s reload

echo "== Cleaning up old container =="
docker rm -f textutills-old

echo "Deploy complete. $ACTIVE_CONTAINER is now running the new image."
