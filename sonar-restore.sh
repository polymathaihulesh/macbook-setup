#!/usr/bin/env bash
# sonar-restore.sh — restore SonarQube Docker volumes onto this Mac.
# Run this ON THE MACBOOK (needs Docker Desktop running).
#
# It pulls the volume tarballs from the Linux box, recreates the volumes,
# restores the data, and prints the `docker run` commands to start SonarQube.
set -euo pipefail

# ---- config ----
LINUX_USER="hulesh"
LINUX_HOST="192.168.31.108"
SRC_DIR="/home/hulesh/sonar-migrate/"     # where the tarballs live on Linux
WORK="$HOME/sonar-migrate"                  # local staging dir on the Mac

# Pinned image versions (MUST match the data, or the DB won't open).
# If a pull 404s, check the exact tag on https://hub.docker.com/_/sonarqube/tags
IMAGE_CB="sonarqube:26.6.0.123539-community"   # active server (sonarqube_cb_data)
IMAGE_LTS="sonarqube:9.9.8-community"          # old 9.9 LTS backup (sonarqube_data)
# ----------------

echo "==> Pulling volume tarballs from $LINUX_HOST ..."
mkdir -p "$WORK"
rsync -avz --progress "$LINUX_USER@$LINUX_HOST:$SRC_DIR" "$WORK/"

restore_volume() {
  local vol="$1" tarball="$WORK/$1.tar.gz"
  if [ ! -f "$tarball" ]; then echo "  skip $vol (no tarball)"; return; fi
  echo "==> restoring volume: $vol"
  docker volume create "$vol" >/dev/null
  docker run --rm -v "$vol":/data -v "$WORK":/backup alpine \
    sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null; tar xzf /backup/$vol.tar.gz -C /data"
}

# Active community server
restore_volume sonarqube_cb_data
restore_volume sonarqube_cb_extensions
# Old 9.9 LTS backup (optional — comment out if you don't need it)
restore_volume sonarqube_data
restore_volume sonarqube_extensions

echo ""
echo "Volumes restored. Now start the ACTIVE server:"
echo ""
echo "  docker pull $IMAGE_CB"
echo "  docker run -d --name sonarqube -p 9000:9000 \\"
echo "    -v sonarqube_cb_data:/opt/sonarqube/data \\"
echo "    -v sonarqube_cb_extensions:/opt/sonarqube/extensions \\"
echo "    $IMAGE_CB"
echo ""
echo "Then open http://localhost:9000  (first boot takes 1-2 min)."
echo ""
echo "To run the OLD 9.9 LTS backup instead (use a different port):"
echo "  docker pull $IMAGE_LTS"
echo "  docker run -d --name sonarqube-old -p 9001:9000 \\"
echo "    -v sonarqube_data:/opt/sonarqube/data \\"
echo "    -v sonarqube_extensions:/opt/sonarqube/extensions \\"
echo "    $IMAGE_LTS"
echo ""
echo "Note: on Apple Silicon, older images may run under emulation (slower)"
echo "but still work. SonarQube also needs Docker Desktop memory >= 4 GB"
echo "(Settings > Resources). If ES fails to start, bump vm.max_map_count:"
echo "  docker run --rm --privileged alpine sysctl -w vm.max_map_count=524288"
