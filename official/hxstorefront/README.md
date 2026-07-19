# HxStorefront — `.hxapp` package

HxStorefront is a **marketplace app** (a hosted store builder), trusted like any
module: it is "official" only because (1) it is served from the `velaris-app-os` org
**and** (2) its id is in the baked-in `case_service/marketplace/official_registry.json`.

This folder holds the **publishing artifacts** for the `Velaris-App-OS/Marketplace`
`official/` folder.

## Files

| File | Role |
|------|------|
| `velaris.json` | Catalogue manifest (keep in sync with `official/sources.json`) |
| `manifest.json` | In-bundle manifest at the root of the `.hxapp` zip |
| `hxstorefront-1.0.0.hxapp` | The package bundle (zip of `manifest.json`) |

## The package-id contract

`velaris/hxstorefront` must be identical in **four** places or it never enables on
install:

1. `velaris.json` `id`
2. `manifest.json` `id`
3. `HXSTOREFRONT_PACKAGE_ID` in `case_service/storefront/common.py` (the install gate)
4. `official_packages` in `case_service/marketplace/official_registry.json`

## Why a `module` `.hxapp` carries no Python

In-process code from a package is FORBIDDEN. The HxStorefront backend
(`case_service/storefront/` + `api/routers/storefront*.py`) and Studio page
(`studio/src/modules/hxstorefront/`) ship **in the Velaris image**, dormant. The
`storefront_*` tables ship via migration 096. Install only writes the
`marketplace_installs` row the in-image gate checks.

## Dependencies

HxStorefront depends on **HxCheckout** (`velaris/hxcheckout`) for order processing —
the public `/checkout` endpoint returns 409 until HxCheckout is also installed for the
tenant. It also uses MinIO (media), and HxConnect/Stripe (via HxCheckout) for payment.

## Install / uninstall lifecycle

- **Install** → `marketplace_installs` row → `/api/v1/storefront` (+ public API) +
  Studio page on.
- **Uninstall · revoke** → admin + public routes 404; all data kept.
- **Uninstall · revoke + delete data** → deletes the tenant's stores, which cascades
  to all `storefront_*` child rows (`app_lifecycle._teardown_hxstorefront`). Order
  cases created via HxCheckout are core data and are untouched.

## v1 scope

Built: stores (multi-store), products + variants + categories, inventory, promotions,
theme (versioned) + page builder (sanitised) + navigation + SEO + sitemap, media
library, public storefront API, and the HxCheckout order bridge (atomic stock,
server-side pricing, promo re-validation). **Deferred:** the `velaris.js` embeddable
SDK and custom-domain / Let's-Encrypt SSL provisioning.
