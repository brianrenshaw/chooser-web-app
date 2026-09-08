# Who’s First?: website migration

Updated September 8, 2026.

## Canonical website

The public website is maintained in **[brianrenshaw-app-site](https://github.com/brianrenshaw/brianrenshaw-app-site)**, locally at `/Users/brianrenshaw/Projects/brianrenshaw-app-site`. Edit its `site/whos-first/` directory for future public website changes. App source and release management remain in this repository.

- App page / Marketing URL: https://brianrenshaw.app/whos-first/
- Support URL: https://brianrenshaw.app/whos-first/support/
- Privacy Policy URL: https://brianrenshaw.app/whos-first/privacy/
- Contact: contact@foliohtml.com
- App Store Connect app ID: `6806757289`

## Compatibility and releases

Previous website: https://brianrenshaw.github.io/chooser-web-app/

Keep the existing GitHub Pages deployment enabled indefinitely. Old marketing/guide pages will redirect after HTTPS is validated at the new domain. Old privacy and support pages retain readable content and link to the new canonical page. Older installed app versions therefore continue to work.
The playable web version has been retired at Brian’s request. The old homepage now markets the iPhone app and will redirect to `/whos-first/` after HTTPS is ready. Deployment excludes the retired browser-game files.

App Store Connect URL changes are separate from website deployment. Update every existing platform/localization where editable; URL changes for released versions may wait for the next app release. Do not create or submit a new version solely as part of this migration. TestFlight URLs are maintained separately. No bundle identifiers, iCloud containers, URL schemes, data-collection declarations, or release states change.

## Deployment and verification

The new site is static HTML/CSS. GitHub Actions validates links, fragments, canonical URLs and font/assets, then deploys `site/`. Hover remains the DNS provider. Four apex A records point to GitHub Pages; `www` is a CNAME to `brianrenshaw.github.io`; existing MX/email settings remain unchanged.

Rollout is in progress. The central [migration log](https://github.com/brianrenshaw/brianrenshaw-app-site/blob/main/MIGRATION.md) is authoritative for HTTPS, legacy redirects, Apple read-back results, remaining release-dependent changes, and verification limits.

Website changes are committed separately from ongoing app work. Existing uncommitted app changes are preserved. Historical submission snapshots may contain the previous URLs; use the canonical values above for the next submission.

The native Five Seats, One Table Icon Composer asset is authoritative. The new page uses the native board palette and native screenshots from the existing build-18 capture set, with Chooser, Tap In and Pinball featured equally. Support instructions reflect version 1.2.

Who’s First? canonical path is `/whos-first/` (support and privacy underneath). Its browser game is retired; legacy `/chooser/` links redirect to the native app website. Pinball is included in the native screenshot gallery.

## HTTPS rollout completed

Certificate approved and HTTPS enforced on September 8, 2026. All 19 routes were fetched over valid TLS and matched local files; www redirects to the HTTPS apex. Legacy compatibility pages are committed/pushed for all four websites. App Store Connect draft URLs for Reading Habit and Where Do We Eat and existing TestFlight URL fields were saved and read back. Released Who’s First? and Folio marketing/support/privacy fields require the next editable app version; old support/privacy pages remain readable. See brianrenshaw-app-site/migration/apple-results.json for exact outcomes.

Remaining: clean current Reading Habit and Where Do We Eat screenshots and responsive visual browser review. Homepage arrows now share one SVG shape.
