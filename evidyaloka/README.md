# eVidyaloka — MacBook Docker setup (staging folder)

These are the Docker files for running **eVidyaloka-jupiter** (Django 4.2 / Python 3.12 / MySQL 8.0 /
Redis) on your Mac. They are kept **separate** from the project repo on purpose — copy them onto the
Mac, then drop them into the project.

## Files here

| File | Goes where on the Mac |
|------|-----------------------|
| `Dockerfile` | **project root** (`eVidyaloka-jupiter/`) |
| `docker-compose.yml` | **project root** |
| `config_docker.py` | **project root** |
| `.dockerignore` | **project root** |
| `DOCKER-SETUP.md` | anywhere (reference doc — full instructions) |
| `db_dumps/` | **project root** — put your `*.sql` DB dump here for auto-import |

> ⚠️ `Dockerfile` and `docker-compose.yml` use `build: .` and mount `.:/app`, so they **must sit at
> the root of the `eVidyaloka-jupiter` project** (next to `manage.py` / `requirements.txt`) to work.

## On the Mac — quick steps

1. Install **Docker Desktop** (Apple Silicon or Intel build) and **MySQL Workbench**.
2. Clone / copy the `eVidyaloka-jupiter` project onto the Mac.
3. Copy the files from this folder into the project root:
   ```bash
   cp Dockerfile docker-compose.yml config_docker.py .dockerignore /path/to/eVidyaloka-jupiter/
   mkdir -p /path/to/eVidyaloka-jupiter/db_dumps
   ```
4. Put your database dump in `eVidyaloka-jupiter/db_dumps/` (e.g. `evd_replica.sql`).
5. From the project root:
   ```bash
   docker compose up -d --build
   ```
6. App → http://localhost:8000 · MySQL → `127.0.0.1:3306` (root / evadmin123).

**Full details, DB export/import, and gotchas are in `DOCKER-SETUP.md`.**

> Nothing here was added to the project repo — these files live only in this staging folder until you
> place them on the Mac.
