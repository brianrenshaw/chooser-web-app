# Who’s First?: website migration

Updated September 8, 2026.

## Ongoing workflow from this app folder

Start website tasks here. Read this document, then work directly in `/Users/brianrenshaw/Projects/brianrenshaw-app-site/site/whos-first/`. There is no automatic sync from native app assets to the website. The shared site repository is authoritative for published pages; older website folders hold compatibility pages or design references.

1. Inspect this app’s current implementation, approved design, and assets. Follow local project instructions, including any device/simulator restrictions. Use real, publication-ready screenshots and record their source; do not present mockups or older captures as newly captured screens.
2. Inspect the shared site repository’s instructions and git status. Update this app’s landing/support/privacy/guide pages and assets as needed. If its icon or summary changes, update the portfolio in `site/index.html` and affected social images too. Preserve canonical paths and legacy links.
3. From `brianrenshaw-app-site`, run `python3 scripts/check_site.py`. Review affected pages at phone and desktop widths when browser access is available; report any visual checks that could not be performed.
4. When publishing is requested, commit only the task’s website changes and push the shared site repository’s `main` branch. GitHub Actions deploys `site/`. Wait for deployment success, then run `python3 scripts/check_live.py` to verify the deployed HTML over HTTPS. Distinguish local changes, pushed changes, and verified live changes.
5. Update this document with material URL, asset-source, or workflow changes and any remaining work. Commit and sync task-specific documentation in this app repository separately. Inspect branches and unpublished commits before pushing; do not publish unrelated app work. Folio’s local release branch may contain unpublished commits—use the existing main-branch checkout for documentation-only sync when necessary.

Ordinary website updates do not require Hover changes, rerunning the migration cutover, or changing Apple metadata. App Store Connect URL edits are separate work when URLs actually change. Keep old support/privacy pages usable and the retired Who’s First? browser game retired.

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
