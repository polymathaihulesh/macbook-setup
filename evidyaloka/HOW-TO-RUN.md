# How to run eVidyaloka locally (Docker, on Mac)

The whole stack — Django app, MySQL, Redis — runs in Docker. You do **not** install
Python, MySQL, or Redis on the Mac. This replaces the old Ubuntu + local-MySQL setup.

| Component | Where it runs |
|-----------|---------------|
| Django 4.2 (Python 3.12) | `web` container → http://localhost:8000 |
| MySQL 8.0 (DB `evd_replica`) | `db` container → `127.0.0.1:3306` |
| Redis 7 | `redis` container → `127.0.0.1:6379` |

> Apple Silicon: the stack is pinned to `linux/amd64` (for the Intel-only `daal4py`
> dependency) and runs under OrbStack's Rosetta emulation. A bit slower, but installs
> every dependency exactly like the old Ubuntu box.

---

## One-time setup (first run)

1. **Start the Docker engine.** This Mac uses **OrbStack** (not Docker Desktop):
   ```bash
   open -a OrbStack
   ```
   Wait until `docker info` works.

2. **Make sure the DB dump is present.** It must sit in `db_dumps/` *before* the first
   start so MySQL auto-imports it. If it's missing, pull it from the Linux box:
   ```bash
   cd ~/macbook-setup && ./move-evidyaloka.sh
   ```
   You should have `db_dumps/evd_replica.sql.gz` (~538 MB).

3. **Build + start everything** (run from the project root):
   ```bash
   cd ~/dev/work/polymath/ev/eVidyaloka-jupiter
   ./mac-setup.sh
   ```
   First run takes several minutes: it builds the image, then MySQL imports the
   ~4.7 GB database. The import keeps running in the background even after the script
   prints "ready" — give it a few minutes before the app stops showing DB errors.

4. Open **http://localhost:8000**

---

## Daily use

```bash
cd ~/dev/work/polymath/ev/eVidyaloka-jupiter

docker compose up -d        # start (fast — no rebuild, no re-import)
docker compose stop         # stop for the day (keeps all data)
docker compose restart web  # restart just the app
docker compose down         # stop + remove containers (DB data is kept in its volume)
docker compose ps           # see what's running
docker compose logs -f web  # tail app logs
docker compose logs -f db   # tail database logs (e.g. while it imports)
```

Code is bind-mounted into the container, so saving a file auto-reloads the dev server —
no rebuild needed for code changes.

---

## MySQL Workbench

Connect to the Dockerized MySQL exactly like a local one:

| Field | Value |
|-------|-------|
| Host | `127.0.0.1` |
| Port | `3306` |
| Username | `root` |
| Password | `evadmin123` |

---

## Common tasks

```bash
# Django management commands
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser
docker compose exec web python manage.py shell

# Open a MySQL shell inside the db container
docker compose exec db mysql -uroot -pevadmin123 evd_replica

# Rebuild the image after changing Dockerfile / requirements
docker compose up -d --build web
```

---

## Reset / re-import the database

The DB lives in a Docker volume and survives `stop`/`down`. To wipe it and re-import
the dump from scratch:

```bash
docker compose down -v      # removes containers + DB volume (data gone)
./mac-setup.sh              # fresh start: rebuilds + re-imports db_dumps/
```

---

## Troubleshooting

- **App shows DB errors right after starting** — MySQL is still importing the dump on
  first boot. Wait a few minutes and refresh. Watch it with `docker compose logs -f db`.
- **`web` container keeps exiting** — check `docker compose logs web`. A
  `ModuleNotFoundError` means a Python package is missing; add it to the `Dockerfile`
  (see the extra `pip install` line) and run `docker compose up -d --build web`.
- **Port already in use (3306 / 8000)** — something else is using the port. Stop the
  other service, or change the left-hand port in `docker-compose.yml`.
- **Engine not running** — `open -a OrbStack` and wait until `docker info` succeeds.

---

## How it's wired (notes for future you)

- `docker-compose.yml` — defines the 3 services. MySQL auto-imports any `*.sql` /
  `*.sql.gz` in `db_dumps/` on first init (mounted at `/docker-entrypoint-initdb.d`).
- `Dockerfile` — Python 3.12 image + system libs + `requirements.txt`, plus a few
  packages the app imports that were missing from `requirements.txt`
  (`python-dotenv`, `SQLAlchemy`, `firebase-admin`).
- `evidyaloka/settings.py` — the DB `HOST` reads `EVD_DB_HOST` (set to `db` by compose;
  empty = local socket for native dev), so the same code runs in Docker and natively.
- `mac-setup.sh` — convenience bootstrap: pre-flight checks → `up --build` → waits for
  MySQL → prints connection info.
</content>
</invoke>
