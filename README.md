# Velaris Marketplace — publishing workspace

This folder is the **source of truth for publishing**, not runtime code. Nothing
here ships inside the Velaris image (the case-service Dockerfile copies only its own
dir). It maps to the public GitHub repo `Velaris-App-OS/Marketplace`:

```
marketplace/
  official/     -> repo official/  (write-protected; only the Velaris org publishes)
    sources.json          the index case-service polls (marketplace_index_url)
    <app>/                velaris.json (record) + manifest.json (in-.hxapp)
                          + <app>-<ver>.hxapp (raw-served bundle) + README
  community/    -> repo community/ (fork + PR; anyone contributes)
    sources.json          the index case-service polls (marketplace_community_index_url)
    source.example.json   per-entry template a contributor adds to sources.json
    APP_TEMPLATE.md       how to describe an app
  push-official.sh        helper: commit + push the official/ folder only
```

## What the platform actually polls

case-service fetches exactly two URLs — `official/sources.json` and
`community/sources.json` — each an `{"packages":[…]}` index, and ingests their
entries into the `marketplace_packages` cache (`_ensure_sources_seeded` +
`_poll_source`). The per-app `velaris.json` / per-contributor source files are
records/templates and are **not** fetched directly: every listed app must have an
entry in its folder's `sources.json`.

## How "Official" is decided (unspoofable)

A package renders **Official** only if ALL THREE hold (re-derived by
`_effective_tier`, never trusted from a manifest):

1. its source URL's GitHub org is in `marketplace_official_orgs` (`velaris-app-os`),
2. its source URL is under the write-protected `official/` folder, **and**
3. its package id is in the baked-in allowlist
   `case_service/marketplace/official_registry.json`.

The folder boundary matters because Official and Community share one repo/org: the
org check alone would bless `community/` too, so the `official/` path is the real
boundary and the registry is the per-id allowlist on top. A manifest cannot
self-tag, and a community contributor cannot append to the registry (it ships in
the platform image — a Velaris release change). So the two tiers safely share this
one repo, split only by folder.

## Lifecycle (what install/uninstall actually do)

Official app **code ships in the Velaris image, dormant**. The `.hxapp` here is
catalogue/discovery metadata. So:

- **Install** → writes a per-tenant `marketplace_installs` row → the app's already-
  in-image routes/UI turn on for that tenant. (Apps with their own tables run a
  Velaris-authored provisioning step; HxTest has none — it reuses the core Test
  Suite tables.)
- **Uninstall · revoke** → gate closes, data kept.
- **Uninstall · revoke + delete data** → also runs the app's registered teardown
  (`case_service/marketplace/app_lifecycle.py`).

## Publish a new official app

1. Add its package id to `case_service/marketplace/official_registry.json`.
2. Add `marketplace/official/<app>/` (velaris.json + manifest.json + README), build
   the bundle and hash it once (`zip -j -X <app>-<ver>.hxapp manifest.json` then
   `sha256sum`), put that exact hash + the raw `download_url` into both the app's
   `velaris.json` and its entry in `official/sources.json`. See
   `official/README.md` for the full recipe; push with `./push-official.sh`.
3. If the app has its own tables, register provisioning + teardown in
   `app_lifecycle.py` (first-party only — third parties stay out-of-process).
