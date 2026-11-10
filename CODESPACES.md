# Coding in the cloud (GitHub Codespaces)

No Flutter, no Xcode, no simulator on the Mac. The SDK, analyzer, formatter and
tests run in GitHub Codespaces; iOS builds run in GitHub Actions.

## First time

1. Open <https://github.com/Pigna099/Musly_pigna>
2. **Code → Codespaces → Create codespace on master**
3. The container builds Flutter 3.47.7 (~5–8 min the first time, cached after).
4. `flutter pub get` runs automatically.

## What works today

```bash
flutter analyze          # same check CI runs
dart format lib test
flutter test
git add/commit/push
```

## What does NOT work

- **`flutter build web`** — upstream Musly imports `dart:io` in `main.dart` and
  19 other files, so the web target does not compile. The README's "Web" support
  claim is stale. A browser preview is therefore not available.
- **No iOS simulator** — Linux containers cannot run one.
- **No hot reload yet.** Visual previews are being redesigned; see the
  "Preview strategy" section in `../PROJECT_NOTES.md`.

## Current loop

1. Edit in Codespaces, run `flutter analyze` and `dart format`.
2. Commit and push.
3. GitHub Actions builds the unsigned `.ipa` (~10–15 min).
4. Download the artifact and sideload it onto the iPhone.

This is slower than hot reload but requires no local disk.
