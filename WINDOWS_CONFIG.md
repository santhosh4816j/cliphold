# Windows-Specific Configuration for ClipHold

This file documents the exact edits to make in the native `windows/` folder
that Flutter generates for you (see SETUP.md for the one-time bootstrap
command). None of this is optional boilerplate you can skip — each item
affects real, user-visible behavior.

## 1. App identity (window title, product name, version)

Edit `windows/runner/Runner.rc`:

- Find `VALUE "ProductName", "cliphold"` → change to `"ClipHold"`
- Find `VALUE "FileDescription", "..."` → change to `"ClipHold — Your clipboard. Remembered. Private."`
- Find `VALUE "CompanyName", "..."` → set to your publisher name
- Bump `FILEVERSION` / `PRODUCTVERSION` to `1,0,0,0` for the first release

Edit `windows/runner/main.cpp`: the window title is already set from
`WindowOptions(title: 'ClipHold')` in `lib/services/window_service.dart`
at runtime, so no change needed there — but confirm the fallback title
passed to `CreateAndShow` (if present in your generated version) also
reads `L"ClipHold"` instead of the default project name.

## 2. App icon

Replace the generated placeholder icon with the one provided in this
project at `windows_config/resources/app_icon.ico`:

```
copy windows_config\resources\app_icon.ico windows\runner\resources\app_icon.ico
```

This `.ico` already contains 16/24/32/48/64/128/256 px sizes (required for
crisp taskbar, Alt-Tab, and Store listing icons). It is a real generated
bitmap (a rounded clipboard glyph in ClipHold's accent blue), not a stub.

## 3. Tray icon asset

The tray icon lives in `assets/icons/tray_icon.ico` (already in this
project and already declared under `flutter: assets:` in `pubspec.yaml`).
`tray_manager` resolves it from the built `flutter_assets` folder
automatically — no native code changes needed. If you want a different
icon, replace that file (keep the `.ico` format; Windows tray icons must
be `.ico`, not `.png`).

## 4. Close button → hide to tray (already implemented)

`lib/main.dart` registers a `WindowListener.onWindowClose` handler and
`WindowService` calls `windowManager.setPreventClose(true)`. This is what
makes clicking the window's X button hide ClipHold to the tray instead of
quitting — required so background clipboard monitoring keeps working.
Nothing to add here; just don't remove `setPreventClose`.

## 5. Launch at Windows startup (optional, for the "Launch at startup" setting)

The Settings screen currently persists a `launch_at_startup` preference
via `SettingsService` but does not yet write a real registry Run-key
entry, because that requires either:

- adding the `launch_at_startup` package (simplest), or
- writing to
  `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`
  yourself via `win32` FFI calls.

This is flagged explicitly rather than faked: add the `launch_at_startup`
package to `pubspec.yaml` and call
`launchAtStartup.setup(appName: 'ClipHold', appPath: Platform.resolvedExecutable)`
+ `launchAtStartup.enable()/.disable()` from a new method on `AppState`
wired to the Settings toggle, if you want this feature enabled.

## 6. Global hotkey conflicts

`hotkey_manager` uses the real Win32 `RegisterHotKey` API. If Alt+V is
already claimed by another running app, registration fails and
`AppState.hotkeyHealthy` becomes `false` — the Settings screen already
surfaces this to the user instead of silently pretending the hotkey
works.

## 7. Microsoft Store packaging (MSIX)

Add to `pubspec.yaml` (dev dependency) and configure:

```yaml
dev_dependencies:
  msix: ^3.16.7

msix_config:
  display_name: ClipHold
  publisher_display_name: <Your Publisher Name>
  identity_name: <YourReservedName.ClipHold>
  msix_version: 1.0.0.0
  logo_path: windows_config/resources/app_icon.ico
  capabilities: ""
  publisher: CN=<Your Publisher GUID from Partner Center>
```

Then build with:

```
flutter pub run msix:create
```

This produces a `.msix` package ready for Partner Center upload. See
`STORE_CHECKLIST.md` for the full submission checklist.
