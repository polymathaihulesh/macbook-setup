# Running the Ujjivan VF stack on the MacBook (current setup)

This documents how the three Ujjivan Vehicle-Finance repos + SonarQube actually
run **on this Mac** after the migration from the Linux box. It captures the real,
working configuration — including the macOS-specific workarounds that were needed.

> Companion docs: `HOW-TO-RESCAN.md` (the scan workflow itself),
> `sonar-restore.sh` (volume restore), `move-dev.sh` / `move-ujjivan.sh` (pulls).

---

## TL;DR — daily commands

```bash
# 1. Make sure the container engine is up (OrbStack)
orb start                       # or just open the OrbStack app

# 2. Make sure SonarQube is running
docker start sonarqube          # idempotent; already-running is fine
#    confirm: http://localhost:9000  (status UP)

# 3. Run scans — IMPORTANT: use Homebrew bash 5, NOT macOS /bin/bash 3.2
cd ~/ujjivan_Repo
/opt/homebrew/bin/bash ./rescan.sh            # all three
/opt/homebrew/bin/bash ./rescan.sh dashboard  # one (backend | dashboard | pulse)
```

Dashboards: http://localhost:9000/projects

---

## What's installed (the toolchain)

| Tool | Version | Why / notes |
|---|---|---|
| **OrbStack** | 2.2.x (Docker 29.4.0) | Container engine — replaces Docker Desktop. Lighter/faster on Apple Silicon. `docker` CLI works as normal. |
| **Homebrew bash** | 5.3.x at `/opt/homebrew/bin/bash` | `rescan.sh` uses `declare -A` (associative arrays) which need Bash 4+. macOS ships only Bash 3.2 (`/bin/bash`), which **fails** with `declare: -A: invalid option`. |
| **Python** | 3.12.13 at `/opt/homebrew/bin/python3.12` | Backend deps (`numpy==2.4.2`, etc.) require Python ≥3.11. macOS system Python is only 3.9.6. |
| **bun** | 1.3.x | Dashboard package manager + vitest coverage. |
| **node / npm** | 24.x / 11.x | Pulse app package manager. |
| **libpq** | latest (`/opt/homebrew/opt/libpq`) | Provides `pg_config` for Postgres client builds. |

Install commands used (for reference / rebuild):
```bash
brew install orbstack
brew install bash
brew install python@3.12
brew install libpq
# bun / node already present
```

---

## The 3 projects

| Script name | Folder | Engine | Coverage | SonarQube key |
|---|---|---|---|---|
| `backend`   | `ujjivan-vf-backend`                | Python 3.12 venv | pytest + pytest-cov | `ujjivan-vf-backend` |
| `dashboard` | `Ujjivan-Vehicle-Finance-dashboard` | bun              | vitest (lcov)       | `ujjivan-vf-dashboard` |
| `pulse`     | `ujjivan-vf-pulse-app`              | npm              | none (no test step) | `ujjivan-vf-pulse-app` |

Reusing the same project keys means each scan **updates the existing project** —
history and trends are preserved, no duplicates.

---

## SonarQube server

- Runs as a Docker container named **`sonarqube`** on **port 9000**.
- Image: `sonarqube:26.6.0.123539-community` (pinned — must match the restored data).
- Data lives in Docker volumes restored from the Linux box:
  - `sonarqube_cb_data`, `sonarqube_cb_extensions` (active server)
  - `sonarqube_data`, `sonarqube_extensions` (old 9.9 LTS backup — not running)
- Admin creds (also baked into `rescan.sh`): `admin` / `Ujjivan@1432`.
  The password lives inside the data volume, so after restore it already matches.

Lifecycle:
```bash
docker start sonarqube     # start
docker stop sonarqube      # stop
docker logs -f sonarqube   # logs
curl -s http://localhost:9000/api/system/status   # {"status":"UP"}
```

If OrbStack was stopped, the container won't be reachable — `orb start` first,
then `docker start sonarqube`.

---

## Per-project setup (one-time, already done)

### Dashboard (bun)
```bash
cd ~/ujjivan_Repo/Ujjivan-Vehicle-Finance-dashboard
bun install
```
- `bun install` blocked 1 postinstall script as untrusted (bun's default). Optional:
  `bun pm untrusted` to inspect, `bun pm trust <pkg>` to allow. Not required to scan.

### Pulse app (npm)
```bash
cd ~/ujjivan_Repo/ujjivan-vf-pulse-app
npm install
```
- npm reports ~68 audit vulnerabilities — normal for an Expo/RN dep tree.
  Do **not** run `npm audit fix --force` (breaks the Expo build).

### Backend (Python 3.12 venv) — the tricky one
```bash
cd ~/ujjivan_Repo/ujjivan-vf-backend
/opt/homebrew/bin/python3.12 -m venv .venv
.venv/bin/pip install --upgrade pip

# Build env so native Postgres deps can find headers:
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/libpq/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libpq/include"

# Install all deps EXCEPT source psycopg2, substituting the prebuilt binary wheel:
grep -ivE '^psycopg2==' requirements.txt > /tmp/reqs.txt
.venv/bin/pip install -r /tmp/reqs.txt psycopg2-binary==2.9.11
.venv/bin/pip install pytest pytest-cov
```

**Why `psycopg2-binary` instead of `psycopg2`?**
The pinned source `psycopg2==2.9.11` fails to build on macOS:
1. needs `pg_config` → fixed by `brew install libpq`
2. then fails to link `-lssl` (OpenSSL not found)

`psycopg2-binary` ships precompiled with libpq+ssl bundled. It is the **same**
`import psycopg2` module/version, so tests and coverage are unaffected. This swap
exists **only inside the venv** — the repo's `requirements.txt` is NOT modified.
(Alternative if you want the source build: `brew install postgresql openssl` and
set `LDFLAGS` to include the openssl lib path.)

---

## Why scans must use `/opt/homebrew/bin/bash`

`rescan.sh` declares associative arrays (`declare -A`). macOS's default
`/bin/bash` is **3.2** (Apple froze it in 2007 over GPLv3) and doesn't support
them — you get `declare: -A: invalid option` and the script aborts immediately.
Always invoke it with Homebrew's Bash 5:

```bash
/opt/homebrew/bin/bash ./rescan.sh <project>
```

(Optionally add an alias in `~/.zshrc`:
`alias rescan='/opt/homebrew/bin/bash ~/ujjivan_Repo/rescan.sh'`.)

---

## Current scan results (baseline)

| Project | Gate | Bugs | Vuln | Hotspots | Smells | Coverage |
|---|---|---|---|---|---|---|
| ujjivan-vf-dashboard | OK    | 23 | 0 | 22 | 826 | 7.6% |
| ujjivan-vf-backend   | ERROR | 0  | 0 | 0  | 511 | 59.4% |
| ujjivan-vf-pulse-app | OK    | 0  | 0 | 0  | 146 | 88.2% |

- Backend coverage is **real** (new-code coverage 100%, overall 59.4%) — the venv
  works. The gate is ERROR only because of **6 new violations** (gate requires 0
  new violations). That's a code-quality result, not a setup failure.
  Review: http://localhost:9000/project/issues?id=ujjivan-vf-backend&inNewCodePeriod=true

---

## Keeping repos clean after scans

Scans drop artifacts (`.scannerwork/`, coverage files, etc.) into each repo. To
keep `git status` clean without touching tracked `.gitignore`, add them to each
clone's untracked `.git/info/exclude` (see `HOW-TO-RESCAN.md` for the block).

> Note: the dashboard repo also shows real edits to `bun.lockb` / `package.json`
> (test/coverage deps) — those are NOT scan artifacts; commit or revert as you wish.

---

## Troubleshooting (Mac-specific)

| Symptom | Cause / Fix |
|---|---|
| `declare: -A: invalid option` | Ran under macOS Bash 3.2. Use `/opt/homebrew/bin/bash ./rescan.sh`. |
| `Cannot connect to the Docker daemon ... .orbstack/run/docker.sock` | OrbStack stopped. `orb start`, then `docker start sonarqube`. |
| `Server did not come UP in time` | SonarQube first boot is slow; re-run. Container may still be starting. |
| `Failed building wheel for psycopg2` (pg_config) | `brew install libpq` and export the build flags, or use `psycopg2-binary`. |
| `ld: library 'ssl' not found` building psycopg2 | OpenSSL missing for the source build. Use `psycopg2-binary` (recommended) or `brew install openssl` + add to `LDFLAGS`. |
| Backend tests fail to import (`No module named pydantic`) | venv deps not installed. Re-run the backend install block above. |
| `numpy`/`pandas` won't install | Wrong Python. Must use `python3.12`, not system `python3` (3.9.6). |

---

## Quick reference

```bash
# start everything
orb start && docker start sonarqube

# scan
cd ~/ujjivan_Repo
/opt/homebrew/bin/bash ./rescan.sh            # all
/opt/homebrew/bin/bash ./rescan.sh backend    # one

# backend tests / coverage by hand
cd ~/ujjivan_Repo/ujjivan-vf-backend
.venv/bin/python -m pytest --cov

# verify repos stayed clean
for d in ujjivan-vf-backend Ujjivan-Vehicle-Finance-dashboard ujjivan-vf-pulse-app; do
  echo "== $d =="; git -C "$d" status --short
done
```
