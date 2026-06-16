# How to re-run SonarQube scans (Ujjivan VF — 3 repos)

This guide explains how to re-scan the three Ujjivan Vehicle-Finance repos
**without changing each repo's git status** — they stay clean ("fresh") — and
while **reusing the same SonarQube project keys** so all history, trends, and
dashboards stay under the same project.

Everything here is driven by `./rescan.sh`. You normally just run that script;
the rest of this doc explains *why* it stays clean and how to fix issues.

---

## TL;DR

```bash
cd ~/ujjivan_Repo
./rescan.sh            # scan all three
./rescan.sh backend   # scan just one (backend | dashboard | pulse)
```

Results print as a table at the end. Dashboards: http://localhost:9000/projects

---

## The 3 projects

| Name in script | SonarQube project key (reused) | Folder | Coverage |
|---|---|---|---|
| `backend`   | `ujjivan-vf-backend`   | `ujjivan-vf-backend`               | Python / pytest |
| `dashboard` | `ujjivan-vf-dashboard` | `Ujjivan-Vehicle-Finance-dashboard`| bun / vitest (lcov) |
| `pulse`     | `ujjivan-vf-pulse-app` | `ujjivan-vf-pulse-app`             | none (no test suite) |

**Same key = same project.** Because the script always passes the same
`-Dsonar.projectKey`, every scan *updates the existing project* instead of
creating a new one. SonarQube keeps the full history/trend line per key — a
re-scan just adds a new analysis point. You do **not** get duplicate projects.

---

## Keeping the repos "fresh" (no git changes from scanning)

Scanning generates files inside each repo. To make sure they **never show up in
`git status`**, exclude them locally. This uses `.git/info/exclude`, which is
**per-clone and untracked** — it does not modify the committed `.gitignore`, so
the repo's tracked state is untouched.

Run this once per machine (safe to re-run):

```bash
cd ~/ujjivan_Repo
for d in ujjivan-vf-backend Ujjivan-Vehicle-Finance-dashboard ujjivan-vf-pulse-app; do
  ex="$d/.git/info/exclude"
  for pat in ".scannerwork/" "sonarqube-reports/" "tsconfig.sonar.json" \
             "coverage/" "coverage.xml" ".coverage" ".pytest_cache/"; do
    grep -qxF "$pat" "$ex" 2>/dev/null || echo "$pat" >> "$ex"
  done
done
echo "Local excludes set — scan artifacts will no longer dirty git status."
```

After this, `git status` in each repo stays clean across as many scans as you
want. To confirm:

```bash
git -C ujjivan-vf-backend status --short    # should be empty after a scan
```

> Note: `tsconfig.sonar.json` is a **leftover from the old SonarQube 9.9 setup**
> and is no longer needed on 26.x. It's excluded above so it won't nag you; you
> can also just delete it from each folder if present.

### Optional: wipe generated artifacts after a scan

If you'd rather remove them entirely instead of just hiding them:

```bash
cd ~/ujjivan_Repo
for d in ujjivan-vf-backend Ujjivan-Vehicle-Finance-dashboard ujjivan-vf-pulse-app; do
  rm -rf "$d/.scannerwork" "$d/sonarqube-reports" "$d/coverage" \
         "$d/coverage.xml" "$d/.coverage" "$d/.pytest_cache" "$d/tsconfig.sonar.json"
done
```

> Heads-up (dashboard only): the dashboard repo currently also shows
> `M bun.lockb` and `M package.json`. Those are **real edits** (test/coverage
> deps), *not* scan artifacts — the excludes above won't hide them. Commit or
> `git checkout` them yourself if you want that repo fully clean.

---

## Prerequisites

1. **Docker Desktop running** (the script auto-starts the `sonarqube` container
   and uses the `sonarsource/sonar-scanner-cli` image over `--network host`).
2. **SonarQube server reachable** at http://localhost:9000 with your data
   restored (see `~/macbook-setup/sonar-restore.sh`).
3. **Coverage tooling per repo** (only needed if you want coverage numbers):
   - backend: a Python venv at `ujjivan-vf-backend/.venv` with pytest + pytest-cov
     ```bash
     cd ujjivan-vf-backend && python3 -m venv .venv
     .venv/bin/pip install -r requirements.txt pytest pytest-cov
     ```
   - dashboard: `bun` installed (`brew install oven-sh/bun/bun`) + deps (`bun install`)
   - pulse: no coverage step, nothing extra needed
   If coverage tooling is missing, the scan **still runs** — it just submits
   without coverage and prints a warning (see `/tmp/cov_<name>.log`).

---

## How a scan works (what the script does)

1. **`ensure_server`** — starts the `sonarqube` container if stopped, waits until
   `/api/system/status` reports `UP`.
2. **`ensure_token`** — reuses the cached token in `/tmp/sonar_token.txt` if still
   valid; otherwise generates a fresh one (named `cli-scan`) via the admin login.
   This is a *SonarQube* token, not a git credential — it never touches the repos.
3. **Per project** — optionally regenerates coverage, then runs the scanner CLI
   in Docker with the same `projectKey` (→ updates the existing project).
4. **`print_results`** — prints quality gate + bugs/vulns/hotspots/smells/coverage
   per project, then links the dashboards.

Logs for each run: `/tmp/sonar_<name>.log` and `/tmp/cov_<name>.log`.

---

## Credentials & config

These live at the top of `rescan.sh` — change them there if needed:

| Setting | Value |
|---|---|
| Server URL | `http://localhost:9000` |
| Admin user | `admin` |
| Admin pass | `Ujjivan@1432` (SonarQube 26.x requires ≥12 chars) |
| Token name | `cli-scan` (cached at `/tmp/sonar_token.txt`) |

The admin password is stored **inside the SonarQube data volume**, so after a
volume restore it already matches — no reset needed.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Server did not come UP in time` | First boot is slow; re-run. Ensure Docker Desktop has ≥4 GB RAM (Settings → Resources). |
| Elasticsearch bootstrap error | `docker run --rm --privileged alpine sysctl -w vm.max_map_count=524288`, then restart the container. |
| `Failed to generate token (check admin password)` | The admin password doesn't match `SONAR_PASS`. Log in at :9000 and reset, then update `rescan.sh`. |
| Scan FAILED for a project | `tail -50 /tmp/sonar_<name>.log` |
| Coverage missing | Check `/tmp/cov_<name>.log`; verify venv/bun deps installed. |
| A new duplicate project appeared | The `projectKey` was changed — keep the keys in the table above to reuse the same project. |
| Git status dirty after scan | Re-run the "Keeping the repos fresh" exclude block above. |

---

## Quick reference

```bash
# scan everything
./rescan.sh

# scan one
./rescan.sh dashboard

# verify repos stayed clean
for d in ujjivan-vf-backend Ujjivan-Vehicle-Finance-dashboard ujjivan-vf-pulse-app; do
  echo "== $d =="; git -C "$d" status --short
done
```
