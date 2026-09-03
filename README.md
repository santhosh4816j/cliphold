# ClipHold

**Your clipboard. Remembered. Private.**

ClipHold is an offline-first Windows desktop clipboard manager built with
Flutter. It watches your clipboard, remembers what you copy, and lets you
find and reuse it instantly — all stored locally, with nothing ever sent
anywhere.

## Features

- **Automatic clipboard history** — every copy is captured and categorized (Text / Links / Code)
- **Smart duplicate handling** — copying the same thing repeatedly bumps a counter instead of spamming your history
- **Instant offline search** — full-text search over your entire history (SQLite FTS5)
- **Pinning** — keep important clips permanently, immune to retention cleanup
- **Copy Back** — one click/tap sends any clip back to the Windows clipboard
- **Quick Paste popup (Alt+V)** — a compact, keyboard-navigable overlay you can summon from any app
- **System tray integration** — open, pause/resume monitoring, clear history, or exit from the tray
- **Snippets** — reusable canned text (signatures, templates) separate from captured history
- **Configurable retention** — auto-delete unpinned clips after 1/7/30/90 days, or never
- **Light & dark mode**, Windows-11-styled Material 3 UI

## Privacy

ClipHold is local-first by design:

- No cloud sync, no accounts, no remote storage
- No analytics, telemetry, or advertising
- Clipboard content is never logged and never leaves your device
- All data lives in a local SQLite database under your Windows user profile

See the in-app Settings screen for the full statement, and `STORE_CHECKLIST.md`
for the privacy-policy requirements if you publish this to the Store.

## Project status

This repository contains the **complete Dart/Flutter implementation** —
every screen, service, repository, and test described below is real,
working code, not a mockup. The only manual step left to you is a
one-time native-scaffold bootstrap (see `SETUP.md`) because generating
Flutter's Windows CMake/C++ runner files requires your local Flutter SDK
version.

## Getting started

See **`SETUP.md`** for full step-by-step instructions. Short version, once
the native `windows/` folder exists:

```
flutter pub get
flutter run -d windows
```

Build a release binary:

```
flutter build windows --release
```

Run tests:

```
flutter test
```

## Architecture

```
lib/
  main.dart                    # entry point, window-close→tray wiring
  models/
    clip_item.dart              # clipboard history row
    snippet.dart                 # user-authored reusable snippet
    enums.dart                   # ClipCategory, RetentionPolicy
  services/
    database_service.dart        # SQLite connection + schema (FTS5 search index)
    clipboard_service.dart       # real OS clipboard-change monitoring + read/write
    hotkey_service.dart          # global Alt+V registration (Win32 RegisterHotKey)
    tray_service.dart            # native system tray icon + menu
    window_service.dart          # main-window ↔ compact-popup mode switching
    settings_service.dart        # persisted user preferences
  repositories/
    clipboard_repository.dart    # clip CRUD, dedup, search, retention
    snippet_repository.dart      # snippet CRUD
  providers/
    app_state.dart               # single source of truth wiring everything together
  screens/
    history_screen.dart, pinned_screen.dart, snippets_screen.dart,
    settings_screen.dart, home_shell.dart, clip_editor_dialog.dart
  widgets/
    clipboard_card.dart, snippet_card.dart, search_bar.dart,
    category_filter.dart, quick_paste_popup.dart
  utils/
    category_detector.dart       # pure, unit-tested auto-categorization + hashing
    ui_helpers.dart               # empty/loading/error state widgets, formatting
  theme/
    app_theme.dart                # Material 3 light/dark Windows-11 styling
test/
  unit/        category detection, repository CRUD/dedup/retention, settings
  widget/      cards, search bar, filters, full History screen flows
```

## How it works

**Where clipboard data is stored** — a SQLite database at
`%LOCALAPPDATA%\ClipHold\cliphold.db` (via `getApplicationSupportDirectory()`),
containing a `clips` table, a `snippets` table, and an FTS5 virtual table
that indexes clip content for fast search. Nothing is stored outside this
one file.

**How monitoring works** — `ClipboardService` uses the `clipboard_watcher`
package, which registers a real Windows clipboard-change listener
(`AddClipboardFormatListener`) rather than polling in a loop. When it
fires, ClipHold reads the new text via `Clipboard.getData` and hands it to
`ClipboardRepository.captureClip`, which normalizes and hashes the content
to detect duplicates before deciding whether to insert a new row or bump
an existing one's `copy_count`.

**How Alt+V works** — `HotkeyService` registers a system-scoped global
hotkey via the `hotkey_manager` package (Win32 `RegisterHotKey` under the
hood), so it fires even when ClipHold isn't the focused window. The
handler calls `AppState.toggleQuickPastePopup()`, which asks
`WindowService` to resize/reposition ClipHold's own window into a compact,
frameless, always-on-top popup and shows it — the same native window used
for the full app, just reshaped, which avoids the extra native complexity
of a true second OS window.

**How the tray works** — `TrayService` uses the `tray_manager` package to
create a real native tray icon with a native right-click context menu
(Open / Pause / Resume / Settings / Clear History / Exit), wired to
`AppState` methods.

**How privacy is maintained** — no network permissions are requested, no
HTTP client is ever instantiated for clipboard data, and every service
that logs errors explicitly logs only error objects/counts — never
clipboard content (see the privacy comments in `database_service.dart`
and `clipboard_service.dart`).

## Testing

- **Unit tests** (`test/unit/`): category auto-detection, content hashing/dedup,
  full `ClipboardRepository` CRUD + duplicate handling + retention, `SnippetRepository`
  CRUD, `SettingsService` persistence.
- **Widget tests** (`test/widget/`): `ClipboardCard` interactions, search bar
  behavior, category filter chips, and full `HistoryScreen` flows (empty state,
  rendering, search filtering, pin, delete) driven through a real in-memory
  SQLite-backed `AppState`.
- **Manual QA**: see `QA_CHECKLIST.md` for everything that can only be verified
  on real Windows (global hotkey, tray, window-close-to-tray, OS clipboard
  integration).

## Publishing to the Microsoft Store

See `STORE_CHECKLIST.md` for the full submission checklist, and
`WINDOWS_CONFIG.md` §7 for MSIX packaging configuration.

## Known follow-ups (flagged, not faked)

- **Launch at Windows startup**: the setting is persisted but not yet wired
  to a real registry Run-key entry — see `WINDOWS_CONFIG.md` §5 for the
  exact package and calls needed to finish this.
- **Multi-monitor popup placement**: the Alt+V popup positions itself
  relative to the window's last-known bounds (works correctly for
  single-monitor and "popup opened from the monitor you're on" cases);
  true per-monitor work-area geometry would need a platform channel to
  Win32's `MonitorFromWindow`/`GetMonitorInfo` if you want pixel-perfect
  placement on unusual multi-monitor layouts.
