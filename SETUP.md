# Setting Up ClipHold Locally (one-time)

Everything in this project's `lib/`, `test/`, and `pubspec.yaml` is
complete, real, runnable Dart code. The one thing that can't be produced
in this environment is the native `windows/` runner folder (CMake + C++
scaffolding), because generating it correctly requires your exact local
Flutter SDK version — hand-writing it risks a version mismatch that
silently breaks your build. So there's one bootstrap step:

## Step 1 — Install prerequisites (if you haven't already)

- Flutter SDK (stable channel), with Windows desktop support enabled:
  ```
  flutter config --enable-windows-desktop
  ```
- Visual Studio 2022 with the "Desktop development with C++" workload
  (required to compile the Windows runner).
- Run `flutter doctor` and resolve any ❌ items before continuing.

## Step 2 — Create the project shell

In an empty folder, run:

```
flutter create --platforms=windows --org com.cliphold cliphold
```

This generates a fresh `windows/`, `android/`, `ios/`, etc. Delete every
generated platform folder except `windows/` (ClipHold only targets
Windows):

```
cd cliphold
rmdir /s /q android ios linux macos web
```

## Step 3 — Drop in ClipHold's source

Copy these from this project into the folder Flutter just created,
**overwriting** the generated placeholders:

- `lib/` → replace the generated `lib/`
- `test/` → replace the generated `test/`
- `pubspec.yaml` → replace the generated one
- `analysis_options.yaml` → replace the generated one
- `assets/` → copy in as a new top-level folder

## Step 4 — Apply the Windows-specific edits

Follow `WINDOWS_CONFIG.md` step by step (icon, product name, tray icon
wiring — all already coded, just needs the two `.ico` files copied in and
`Runner.rc` text fields updated).

## Step 5 — Install dependencies and run

```
flutter pub get
flutter run -d windows
```

## Step 6 — Run the test suite

```
flutter test
```

## Step 7 — Build a release build

```
flutter build windows --release
```

The output `.exe` and its dependencies will be in
`build/windows/x64/runner/Release/`.

---

If `flutter pub get` reports a version conflict on any package (package
APIs do shift over time), run `flutter pub outdated` and bump the
constraint in `pubspec.yaml` for just that package — the rest of the
codebase does not depend on exact package internals, only on the public
APIs documented in each service file's comments.
