# HxCheckout — `.hxapp` package

HxCheckout is a **marketplace app**, not a platform feature with an on/off flag. It
is published, installed, and trusted like any module — the *only* thing that makes
it "official" is that (1) it is served from the `velaris-app-os` org **and** (2) its
id is in the baked-in allowlist `case_service/marketplace/official_registry.json`.
`_effective_tier()` requires both; the manifest never decides its own tier.

This folder holds the **publishing artifacts** (the source for the GitHub
`Velaris-App-OS/Marketplace` `official/` folder).

## Files

| File | Role | Consumed by |
|------|------|-------------|
| `velaris.json` | Catalogue manifest served at the source URL | `case-service` `_poll_source()` → `marketplace_packages` cache |
| `manifest.json` | In-bundle manifest at the root of the `.hxapp` zip | `checksum.parse_and_validate_manifest()` at download + promotion |
| `hxcheckout-1.0.0.hxapp` | The package bundle (zip of `manifest.json`) | downloaded + checksum-verified at install |

## The package-id contract (load-bearing)

`velaris/hxcheckout` must be identical in **four** places or HxCheckout never
enables on install:

1. `velaris.json` `id`
2. `manifest.json` `id`
3. `HXCHECKOUT_PACKAGE_ID` in `case_service/api/routers/checkout.py` (the install gate)
4. `official_packages` in `case_service/marketplace/official_registry.json` (the Official-tier allowlist)

The gate query is: *is there a non-revoked `marketplace_installs` row with
`package_id = velaris/hxcheckout` for this tenant?* That is the entire enablement
mechanism — the standard "feature flag enabled on install" path every `module`
package uses. There is no `checkout_enabled` setting.

## Why a `module` `.hxapp` carries no Python

In-process code from a package is FORBIDDEN (see
`docs/Future/marketplace-execution-trust-model.md`). The HxCheckout backend
(`case_service/checkout/` + `api/routers/checkout.py`) and Studio page
(`studio/src/modules/hxcheckout/`) ship **in the Velaris image**, dormant. The
`checkout_*` tables ship on the normal startup migration track (095). The `.hxapp`
is catalogue metadata + per-tenant enablement only — install does not download or
execute code; it writes the `marketplace_installs` row the in-image gate checks.

## Building the `.hxapp`

```
cd marketplace/official/hxcheckout
zip -X hxcheckout-1.0.0.hxapp manifest.json
sha256sum hxcheckout-1.0.0.hxapp     # paste into velaris.json + official/sources.json
```

## Install / uninstall lifecycle

Unlike HxTest, HxCheckout **has its own tables** (`checkout_*`). They ship via
migration 095 (always present), so install is still just the gate flip:

- **Install** → `marketplace_installs` row → `/api/v1/checkout` + Studio page on.
- **Uninstall · revoke** → gate 404s, page hides, all data kept (re-install is instant).
- **Uninstall · revoke + delete data** → also deletes the tenant's `checkout_*` rows
  (orders + items + notifications via FK cascade, tokens, integrations + events) via
  `app_lifecycle._teardown_hxcheckout`. The Order/Return/Complaint **cases** are core
  case-service data and are NOT deleted (orders FK to cases is `ON DELETE SET NULL`).

## To activate end-to-end

1. Activate the marketplace (`marketplace_dev_only=False`) — creates the
   `marketplace_installs` table.
2. Publish this package (above). `marketplace_official_orgs` defaults to
   `velaris-app-os` and `velaris/hxcheckout` is in the registry → tier resolves to `official`.
3. Install `velaris/hxcheckout` into a tenant → checkout routes + Studio page light up.
   Until then HxCheckout is **dark** (the gate 404s) — by design.
4. Configure a Stripe connector (HxConnect) for inline payment; without one, orders
   fall back to invoice/COD (no `payment_url`).
