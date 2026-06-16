# eVidyaloka — Docker setup on Mac

Run the eVidyaloka Django app + MySQL + Redis in Docker on your Mac, matching the
current Ubuntu dev environment, and import the existing database.

| Component | Version (matches current env) |
|-----------|-------------------------------|
| Python | 3.12 |
| Django | 4.2 |
| MySQL | 8.0 |
| Redis | 7 (for Django Channels) |
| DB driver | mysqlclient 2.2.1 |

---

## 1. What to install on your Mac

| Tool | Why | How |
|------|-----|-----|
| **Docker Desktop** | Runs the whole stack (app + MySQL + Redis) | https://www.docker.com/products/docker-desktop/ — pick the **Apple Silicon** build (M1/M2/M3) or **Intel** build to match your Mac |
| **MySQL Workbench** | You already use it — connect to the Dockerized MySQL | https://dev.mysql.com/downloads/workbench/ (macOS) |
| **Git** | Clone the repo | `xcode-select --install` (or Homebrew) — usually already present |

That's it. **You do NOT install Python, MySQL server, or Redis on the Mac** — they all run inside Docker.

> ⚠️ **Apple Silicon note:** this project depends on `daal4py` (Intel x86-only). The Docker files are
> set to `platform: linux/amd64`, so the stack runs as x86 via Docker Desktop's Rosetta emulation.
> It's a bit slower but installs every dependency exactly as on the Ubuntu machine — no code changes.
> In Docker Desktop, enable **Settings → General → "Use Rosetta for x86/amd64 emulation"**.

---

## 2. Files added to the repo

| File | Purpose |
|------|---------|
| `Dockerfile` | Python 3.12 image + system libs for `mysqlclient`/Pillow/cryptography + `pip install -r requirements.txt` |
| `docker-compose.yml` | 3 services: `web` (Django), `db` (MySQL 8.0), `redis` |
| `config_docker.py` | Same as `config_dev.py` but DB `HOST='db'` (the compose service). Copied to `config.py` on startup |
| `.dockerignore` | Keeps `venv/`, `.git`, dumps out of the image |

---

## 3. Start the stack

```bash
cd eVidyaloka-jupiter
docker compose up -d --build        # first build takes a while (installs all deps)
docker compose logs -f web          # watch it boot
```

Then open **http://localhost:8000**.

Run migrations / create a superuser if needed:
```bash
docker compose exec web python manage.py migrate
docker compose exec web python manage.py createsuperuser
```

Stop / restart:
```bash
docker compose stop          # stop (keeps data)
docker compose up -d         # start again
docker compose down          # stop + remove containers (DB data persists in the volume)
docker compose down -v       # ALSO wipe the DB volume (fresh start)
```

---

## 4. Transfer the database (this is the important part)

The active DB is **`evd_replica`** (~4.7 GB). `evidyaloka_test` (~16 MB) is the small schema/test DB.
Pick whichever you actually need.

### Step A — Export from the current (Ubuntu) machine

**Option 1 — command line (recommended for a 4.7 GB DB):**
```bash
# On the Ubuntu machine:
mysqldump -u root -pevadmin123 --single-transaction --quick \
  --routines --triggers evd_replica | gzip > evd_replica.sql.gz
# (optionally also the small one)
mysqldump -u root -pevadmin123 evidyaloka_test > evidyaloka_test.sql
```
`--single-transaction --quick` streams a large DB without locking it or blowing up memory.

**Option 2 — MySQL Workbench (GUI):**
Server → **Data Export** → select `evd_replica` → "Export to Self-Contained File" → Start Export.

### Step B — Copy the dump to your Mac
Use AirDrop / a USB drive / `scp` / cloud storage. For 4.7 GB, the gzip in Option 1 helps a lot.

### Step C — Import into the Dockerized MySQL on the Mac

**Easiest — auto-import on first start:** put the dump in `db_dumps/` *before* the first `docker compose up`:
```bash
mkdir -p db_dumps
gunzip -c evd_replica.sql.gz > db_dumps/evd_replica.sql   # must be plain .sql here
docker compose up -d        # MySQL auto-loads everything in db_dumps/ on first init
```
> This only runs on a **fresh** DB volume (first start). If you already started once, use the manual import below or `docker compose down -v` first.

**Manual import (anytime):**
```bash
# plain .sql
docker compose exec -T db mysql -u root -pevadmin123 evd_replica < evd_replica.sql
# or straight from gzip
gunzip -c evd_replica.sql.gz | docker compose exec -T db mysql -u root -pevadmin123 evd_replica
```

**Via MySQL Workbench on the Mac:** add a connection → Host `127.0.0.1`, Port `3306`, User `root`,
Password `evadmin123` → **Data Import** → import the `.sql` file into `evd_replica`.

---

## 5. Connecting MySQL Workbench (Mac) to the Docker DB

| Field | Value |
|-------|-------|
| Host | `127.0.0.1` |
| Port | `3306` |
| Username | `root` |
| Password | `evadmin123` |

(The `db` service publishes `3306` to the Mac, so Workbench connects as if MySQL were local.)

---

## 6. Notes / gotchas

- **DB host:** inside the `web` container, the DB is reached at `db`, not `localhost` — handled by
  `config_docker.py` → `config.py`. Don't change `config_dev.py`.
- **Credentials:** compose sets MySQL root password to `evadmin123` (matches `.env`). If your real DB
  uses different creds, update `docker-compose.yml` (`MYSQL_ROOT_PASSWORD`) and `config_docker.py`.
- **First boot is slow** (building the image + Rosetta emulation). Subsequent starts are fast.
- **Big DB import takes time** — a 4.7 GB dump can take many minutes; let it finish before using the app.
- **Don't commit dumps:** `db_dumps/` and `*.sql` are git-ignored.
