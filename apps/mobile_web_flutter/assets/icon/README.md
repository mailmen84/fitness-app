# App icon assets

This folder holds the source image used by `flutter_launcher_icons` to
generate launcher icons for Android, iOS, and the web build.

Files:

- `app_icon.png` — 1024x1024 source icon. Used for Android legacy icon, iOS,
  and web favicon.
- `app_icon_foreground.png` — 1024x1024 transparent foreground used for
  Android adaptive icons. Pair with the background color configured in
  `pubspec.yaml` (`adaptive_icon_background`).

Both files in the repository are placeholders (teal lettermark "F"). Replace
them with the final brand artwork before a release build. Keep the same file
names so the generator config does not need to change.

## Regenerating native icons

After replacing the source images:

```powershell
cd apps/mobile_web_flutter
flutter pub get
dart run flutter_launcher_icons
```

The tool will write into `android/app/src/main/res/`, the iOS asset catalog,
and `web/icons/`. Commit those generated files together with the new sources
so a fresh checkout does not need to run the generator before building.
