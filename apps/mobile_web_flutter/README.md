# mobile_web_flutter

Cross-platform Flutter client scaffold for `fitness-app`.

## Current state

- Dart and Flutter app layers are in place.
- Multi-platform folders are prepared for Android, iOS, web, Linux, macOS, and Windows.
- Native runner files still need to be generated with Flutter tooling.

## Bootstrap native runners

```bash
flutter create . --platforms=android,ios,web,windows,linux,macos
```

## Run

```bash
flutter pub get
flutter run -d chrome
```
