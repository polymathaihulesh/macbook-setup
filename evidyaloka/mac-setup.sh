#!/usr/bin/env bash
# ===========================================================================
# eVidyaloka — one-command Docker bootstrap. RUN THIS ON THE MAC.
#
# Place this file (and the other Docker files + db_dumps/) at the ROOT of the
# eVidyaloka-jupiter project, then:
#
#     ./mac-setup.sh
#
# It builds the image, starts MySQL + Redis + the Django app, waits for the
# database dump to finish importing, and prints the URL.
# ===========================================================================
set -euo pipefail

say()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✔ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m  ✘ %s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. Pre-flight checks -------------------------------------------------
say "Checking prerequisites"
command -v docker >/dev/null 2>&1 || die "Docker not found. Install Docker Desktop for Mac first."
docker info >/dev/null 2>&1       || die "Docker Desktop isn't running. Open it (whale icon), wait until it's started, then re-run."
[ -f docker-compose.yml ]         || die "docker-compose.yml not found. Run this from the eVidyaloka-jupiter project root."
[ -f manage.py ]                  || warn "manage.py not found here — make sure these files are at the project root."
ok "Docker is running"

# --- 2. DB dump present? --------------------------------------------------
say "Checking for the database dump"
if ls db_dumps/*.sql.gz db_dumps/*.sql >/dev/null 2>&1; then
  ok "Found a dump in db_dumps/ — MySQL will auto-import it on first start."
  # optional integrity check if a checksum sits beside it
  if [ -f db_dumps/evd_replica.sql.gz.sha256 ]; then
    ( cd db_dumps && shasum -a 256 -c evd_replica.sql.gz.sha256 >/dev/null 2>&1 ) \
      && ok "Dump checksum verified (file is intact)." \
      || warn "Dump checksum did NOT match — the file may be incomplete/corrupt."
  fi
else
  warn "No dump in db_dumps/ — the database will start EMPTY."
  warn "Copy evd_replica.sql.gz into db_dumps/ and re-run to import the data."
fi

# --- 3. Build + start -----------------------------------------------------
say "Building image and starting containers (first run takes several minutes)"
docker compose up -d --build
ok "Containers started"

# --- 4. Wait for MySQL (the dump import happens during first init) --------
say "Waiting for MySQL to finish initializing / importing (can take many minutes for a large dump)"
printf "  "
for i in $(seq 1 180); do          # up to ~30 min (180 x 10s)
  if docker compose exec -T db mysqladmin ping -uroot -pevadmin123 >/dev/null 2>&1; then
    echo; ok "MySQL is ready."
    break
  fi
  printf "."
  sleep 10
  if [ "$i" -eq 180 ]; then echo; warn "Still initializing after 30 min — check: docker compose logs -f db"; fi
done

# --- 5. Done --------------------------------------------------------------
say "Status"
docker compose ps

printf '\n\033[1;32mReady.\033[0m\n'
cat <<EOF
  • App:            http://localhost:8000
  • MySQL (Workbench): host 127.0.0.1  port 3306  user root  password evadmin123
  • Logs:           docker compose logs -f web
  • Stop:           docker compose stop
  • Start again:    docker compose up -d
  • Reset DB:       docker compose down -v   (wipes data, re-imports on next up)

If the app shows DB errors right after start, MySQL may still be importing —
wait a bit and refresh, or watch:  docker compose logs -f db
EOF
