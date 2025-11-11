# Firebase configuration (securing API keys)

This project reads Firebase configuration values from Dart environment variables so
API keys and other identifiers are not committed to source control.

How to provide values at build/run time:

- Flutter run (mobile):
  flutter run --dart-define=FIREBASE_ANDROID_API_KEY=... --dart-define=FIREBASE_ANDROID_APP_ID=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=FIREBASE_DATABASE_URL=... --dart-define=FIREBASE_STORAGE_BUCKET=...

- Flutter build (android):
  flutter build apk --dart-define=FIREBASE_ANDROID_API_KEY=... --dart-define=FIREBASE_ANDROID_APP_ID=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=FIREBASE_DATABASE_URL=... --dart-define=FIREBASE_STORAGE_BUCKET=...

- Web (provide web keys):
  flutter run -d chrome --dart-define=FIREBASE_WEB_API_KEY=... --dart-define=FIREBASE_WEB_APP_ID=... \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=FIREBASE_AUTH_DOMAIN=... --dart-define=FIREBASE_DATABASE_URL=... \
    --dart-define=FIREBASE_STORAGE_BUCKET=... --dart-define=FIREBASE_MEASUREMENT_ID=...

Helper script (local development)

- Copy `.env.example` to `.env` and fill in your values. `.env` is ignored by git.
- Run the helper to automatically pass env values to flutter:

```bash
# Example: run on chrome
./scripts/load_firebase_env.sh run -d chrome

# Example: build android
./scripts/load_firebase_env.sh build apk
```

Tips:
- For CI, add the same variables to your pipeline secrets and pass them as --dart-define when building.
- If keys are accidentally committed, rotate them in the Firebase console immediately.
