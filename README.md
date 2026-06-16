# Velaris Marketplace — publishing workspace

This folder is the **source of truth for publishing**, not runtime code. Nothing
here ships inside the Velaris image (the case-service Dockerfile copies only its own
dir). It maps to the public GitHub repo `Velaris-App-OS/Marketplace`:

```
marketplace/
  official/     -> repo official/  (write-protected; only the Velaris org publishes)
    <app>/        velaris.json (catalogue) + manifest.json (in-.hxapp) + README
  community/    -> repo community/ (fork + PR; anyone contributes)
    source.example.json   the URL file a contributor forks to list their app
    APP_TEMPLATE.md       how to describe an app
```

## How "Official" is decided (unspoofable)

A package renders **Official** only if BOTH hold:

1. its source URL's GitHub org is in `marketplace_official_orgs` (`velaris-app-os`), **and**
2. its package id is in the baked-in allowlist
   `case_service/marketplace/official_registry.json`.

The manifest never decides its own tier, and a community contributor cannot append
to the registry (it ships in the platform image — a Velaris release change). So
Official and Community can safely share this one repo, split only by folder.

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
2. Add `marketplace/official/<app>/` (velaris.json + manifest.json + README) and
   publish the `.hxapp` to the GitHub `official/` folder; PR the catalogue entry
   into `official/sources.json`.
3. If the app has its own tables, register provisioning + teardown in
   `app_lifecycle.py` (first-party only — third parties stay out-of-process).
