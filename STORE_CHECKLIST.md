# Microsoft Store Preparation Checklist

## Account & reservation
- [ ] Register a Microsoft Partner Center developer account
- [ ] Reserve the app name "ClipHold" in Partner Center
- [ ] Note the assigned Package Identity Name and Publisher ID (needed for `msix_config`)

## Packaging (MSIX)
- [ ] Add the `msix` package and `msix_config` block to `pubspec.yaml` (see `WINDOWS_CONFIG.md` §7)
- [ ] Set `identity_name`, `publisher`, `publisher_display_name`, `display_name`, `msix_version` to match Partner Center exactly
- [ ] Run `flutter build windows --release`
- [ ] Run `flutter pub run msix:create`
- [ ] Test-install the generated `.msix` locally (double-click it) before submitting

## App capabilities & manifest
- [ ] Confirm the app requests NO unnecessary capabilities (no network, no camera, no microphone — ClipHold needs none of these)
- [ ] Confirm the manifest does NOT declare internet client capability unless a future feature genuinely needs it (keep the "fully offline" claim true)

## Store listing content
- [ ] App name: ClipHold
- [ ] Short description / tagline: "Your clipboard. Remembered. Private."
- [ ] Long description drafted, emphasizing: local-first, no cloud, no accounts, no tracking
- [ ] Category: Productivity
- [ ] At least 3–5 screenshots at required Store resolution (History view, Quick Paste popup, Settings/privacy panel, Snippets)
- [ ] App icon exported at all required Store tile sizes (Partner Center will regenerate most from the 300×300+ master; use `windows_config/resources/app_icon.ico`'s source or re-export at 512×512+ PNG for best results)
- [ ] Privacy policy URL (required even for local-only apps) — a simple one-page statement is enough given ClipHold collects nothing

## Privacy policy content (must-haves)
- [ ] Explicitly states ClipHold does not transmit clipboard content anywhere
- [ ] Explicitly states no analytics/telemetry/advertising SDKs are present
- [ ] Explains what local data is stored (clipboard history, snippets, settings) and where (local SQLite file under the user's app-data folder)
- [ ] Explains how the user can delete all data (Clear History in-app, or uninstalling the app)

## Age rating & compliance
- [ ] Complete the Microsoft age rating questionnaire (ClipHold should qualify for the lowest/all-ages rating — no objectionable content)
- [ ] Confirm compliance with Microsoft Store Policies §10 (data privacy) — straightforward given no data leaves the device

## Pre-submission technical checks
- [ ] `flutter build windows --release` completes with no errors or warnings you can't explain
- [ ] `flutter test` passes fully
- [ ] App launches correctly on a clean Windows VM (not just your dev machine) — catches missing-dependency issues
- [ ] App handles being run for the first time ever (no pre-existing DB) gracefully — creates the DB and shows the correct empty states
- [ ] Uninstalling the app removes it cleanly (standard MSIX behavior; confirm no orphaned tray icon after uninstall)
- [ ] Global hotkey and tray icon both work when launched from the Store-installed location (not just from `flutter run`)

## Submission
- [ ] Upload the `.msix` package in Partner Center
- [ ] Fill in pricing (free) and market availability
- [ ] Submit for certification
- [ ] Monitor the certification report for any automated flags (most common: missing privacy policy link, capability mismatches)
