# Velaris Marketplace — Official apps

This folder is the **write-protected source of the Official tier**. Only the
`Velaris-App-OS` org can publish here, and a package is shown as **Official** only
when *all* of the following hold (re-derived by `_effective_tier`, never trusted
from a manifest):

1. the source URL's GitHub org is in `marketplace_official_orgs` (`velaris-app-os`),
2. the source URL is under this `official/` folder, **and**
3. the package id is in the baked-in allowlist
   `case_service/marketplace/official_registry.json`.

## What the platform actually reads

`marketplace_index_url` points at **`official/sources.json`**. case-service seeds it
as the "Velaris Official" source (`_ensure_sources_seeded`) and `_poll_source()`
reads the `packages[]` array from it into the `marketplace_packages` cache. That is
the *only* file the platform fetches for discovery — the per-app `velaris.json`
files are records/source-of-truth and are **not** fetched directly (keep each one in
sync with its `sources.json` entry).

| File | Role | Consumed by |
|------|------|-------------|
| `sources.json` | Official index — `{"packages":[…]}` | `_poll_source()` → `marketplace_packages` |
| `<app>/velaris.json` | Per-app catalogue record (kept in sync with the index) | reference only |
| `<app>/manifest.json` | In-bundle manifest at the root of the `.hxapp` zip | `checksum.parse_and_validate_manifest()` at install |
| `<app>/<app>-<ver>.hxapp` | The downloadable bundle (raw-served) | install: download + `verify_checksum` + manifest validate |

## Publishing a new official app

1. Add the package id to `official_packages` in
   `case_service/marketplace/official_registry.json` (a platform-release change — this
   is what makes the Official tier unspoofable).
2. Create `official/<app>/` with `manifest.json` (in-bundle) and `velaris.json` (record).
3. Build the bundle and hash it **once**:
   ```
   zip -j -X <app>/<app>-<ver>.hxapp <app>/manifest.json   # + any bundled DSL tests
   sha256sum <app>/<app>-<ver>.hxapp
   ```
4. Put that exact hash + the raw `download_url` into both the app's `velaris.json`
   and its entry in `sources.json`. Do not rebuild after hashing (zip timestamps
   change the digest).
5. Commit `official/` and push to `main`. raw.githubusercontent serves the committed
   bytes, so the install-time checksum will match.

Community submissions go through the `community/` folder (fork + PR) and are always
Community tier — see `../community/` and `../README.md`.
