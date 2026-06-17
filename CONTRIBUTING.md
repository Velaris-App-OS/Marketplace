# Contributing to the Velaris Marketplace

This repo has two folders with two different rules.

## `community/` — open to everyone

Anyone can list an app:

1. **Fork** `Velaris-App-OS/Marketplace`.
2. Add one entry to the `packages[]` array in `community/sources.json`
   (use `community/source.example.json` as the per-entry template; see
   `community/APP_TEMPLATE.md` for the write-up).
3. Host your `.hxapp`, set `download_url`, and set `checksum_sha256` to the
   sha256 of that exact file.
4. Open a PR. A maintainer reviews and merges.

Community apps are **always Community tier** and run out-of-process — they can
never gain the Official badge (see below).

## `official/` — Velaris team only

The `official/` folder is restricted to the Velaris team (enforced by
`.github/CODEOWNERS` + branch protection requiring Code Owner review). External
contributors cannot publish here; PRs touching `official/` require Velaris-team
approval to merge.

## Why this is safe regardless of repo permissions

The **Official** badge is not granted by this repo. `_effective_tier` requires a
package id to be in `case_service/marketplace/official_registry.json` — which ships
inside the Velaris platform image (a release change) — **and** be served from the
`official/` folder. A repo write alone can never add a registry entry, so the
Official tier is unspoofable even if folder permissions were misconfigured.
