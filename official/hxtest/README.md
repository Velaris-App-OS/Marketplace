# HxTest — `.hxapp` package (draft)

HxTest is a **marketplace app**, not a platform feature with an on/off flag. It is
published, installed, and trusted like any module — the *only* thing that makes it
"official" is that (1) it is served from the `velaris-app-os` org **and** (2) its id
is in the baked-in allowlist `case_service/marketplace/official_registry.json`.
`_effective_tier()` requires both; the manifest never decides its own tier, so a
third party cannot self-tag official.

This folder holds the **publishing artifacts** (the source for the GitHub
`Velaris-App-OS/Marketplace` `official/` folder). Nothing here ships in the image
or creates the GitHub repo — that infra is yours to stand up.

## Files

| File | Role | Consumed by |
|------|------|-------------|
| `velaris.json` | Catalogue manifest served at the source URL | `case-service` `_poll_source()` → `marketplace_packages` cache |
| `manifest.json` | In-bundle manifest at the root of the `.hxapp` zip | `checksum.parse_and_validate_manifest()` at download + promotion |

## The package-id contract (load-bearing)

`velaris/hxtest` must be identical in **four** places or HxTest never enables on
install:

1. `velaris.json` `id`
2. `manifest.json` `id`
3. `HXTEST_PACKAGE_ID` in `case_service/api/routers/hxtest.py` (the install gate)
4. `official_packages` in `case_service/marketplace/official_registry.json` (the Official-tier allowlist)

The gate query is: *is there a non-revoked `marketplace_installs` row with
`package_id = velaris/hxtest` for this tenant?* That is the entire enablement
mechanism — the standard "feature flag enabled on install" path every `module`
package uses. There is no `hxtest_enabled` setting (removed).

## Why a `module` `.hxapp` carries no Python

Per `docs/Future/marketplace-execution-trust-model.md`, in-process code from a
package is FORBIDDEN. The HxTest backend (`case_service/hxtest/`) and Studio page
(`studio/src/modules/hxtest/`) ship **in the Velaris image**, dormant. The `.hxapp`
is catalogue metadata + per-tenant enablement (+ optional Phase-F bundled DSL
tests). Install does not download or execute code; it writes the
`marketplace_installs` row that the in-image gate checks.

## Building the `.hxapp`

```
zip hxtest-2.0.0.hxapp manifest.json   # + any bundled DSL test files
sha256sum hxtest-2.0.0.hxapp           # paste into velaris.json checksum_sha256
```

Then host the artifact (e.g. a GitHub release asset), point `download_url` at it,
and PR the `velaris.json` entry into the `Velaris-App-OS/Marketplace`
`official/sources.json`.

## Install / uninstall lifecycle

HxTest **adds no tables of its own** — it reuses the core Test Suite's `hxtest_*`
tables. So install is purely the gate flip, and "delete data" removes only the
AI-generated suites:

- **Install** → `marketplace_installs` row → `/api/v1/hxtest` + Studio page on.
- **Uninstall · revoke** → gate 404s, page hides, generated suites kept.
- **Uninstall · revoke + delete data** → also deletes `ai_generated` suites +
  their runs/results (`app_lifecycle._teardown_hxtest`); core suites untouched.

## To activate end-to-end

1. Create the `Velaris-App-OS/Marketplace` repo with `official/` + `community/` (your infra).
2. Activate the marketplace (`marketplace_dev_only=False`) — this also creates the
   `marketplace_workspaces`/`marketplace_installs` tables and lands migration 092 +
   the conformance gate live.
3. Publish this package (above). `marketplace_official_orgs` defaults to
   `velaris-app-os` and `velaris/hxtest` is in the registry, so tier resolves to `official`.
4. Install `velaris/hxtest` into a tenant → HxTest routes + Studio page light up.
   Until then HxTest is **dark** (the gate 404s) — by design.
