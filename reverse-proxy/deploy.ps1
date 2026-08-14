# deploy.ps1
# Checks Docker Hub for a newer textutills image; if found, starts it
# alongside the current one, health-checks it, then swaps it in with a
# live Nginx reload - zero downtime, same sequence you just did by hand.

$Image = "abhaysingh42852/textutills:latest"
$Network = "textutills-net"
$ProxyContainer = "textutills-proxy"
$ActiveContainer = "textutills-active"
$NewContainer = "textutils-new"

Write-Host "== Checking for a new image =="

# Get the image ID currently backing the running "active" container.
# This tells us what's actually deployed right now, not just what tag
# is running - the tag "latest" can point at different images over time.
$currentImageId = docker inspect --format='{{.Image}}' $ActiveContainer

# Pull whatever "latest" currently points to on Docker Hub.
docker pull $Image | Out-Null

# Get the image ID of what we just pulled.
$latestImageId = docker inspect --format='{{.Id}}' $Image

if ($currentImageId -eq $latestImageId) {
    Write-Host "No new image found. Nothing to do."
    exit 0
}

Write-Host "New image detected. Starting new container: $NewContainer"

# Clean up any leftover container from a previous failed attempt, so this
# script is safe to re-run even after a prior failure.
docker rm -f $NewContainer 2>$null

docker run -d `
  --name $NewContainer `
  --network $Network `
  --restart unless-stopped `
  $Image | Out-Null

Write-Host "== Health-checking the new container =="

# Give the new container a few chances to respond before giving up -
# it needs a moment to fully start.
$healthy = $false
for ($i = 1; $i -le 5; $i++) {
    Start-Sleep -Seconds 2
    $result = docker exec $ProxyContainer wget -qO- "http://${NewContainer}:80" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $healthy = $true
        break
    }
    Write-Host "Attempt $i not healthy yet, retrying..."
}

if (-not $healthy) {
    Write-Host "New container failed health check. Rolling back - old container untouched."
    docker rm -f $NewContainer
    exit 1
}

Write-Host "== Healthy. Swapping into place =="

# Give the old active container a temporary name so the new one can take
# over the name Nginx is configured to route to.
docker rename $ActiveContainer "textutils-old"

# The new container takes the name Nginx expects. nginx.conf itself is
# never edited - only which container currently holds this name changes.
docker rename $NewContainer $ActiveContainer

# Force Nginx to re-resolve the name and pick up the new container's IP.
# This is the actual "cutover" moment - graceful, no dropped connections.
docker exec $ProxyContainer nginx -s reload

Write-Host "== Cleaning up old container =="
docker rm -f "textutils-old"

Write-Host "Deploy complete. $ActiveContainer is now running the new image."
