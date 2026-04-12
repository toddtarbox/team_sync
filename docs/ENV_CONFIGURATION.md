# Environment Configuration (.env)

This project reads Firebase and other secrets from `.env` files **at compile time**, not runtime. This means secrets are injected during the build process, not hardcoded in the repository.

## How It Works

### Overview

1. **`.env` file** (gitignored) contains all secrets and configuration
2. **Build scripts** read `.env` during compilation
3. **Platform-specific config files** are generated with the values
4. **CI/CD** uses GitHub Secrets or environment variables (takes precedence over `.env`)

### Build-Time Configuration by Platform

#### Android (`android/app/build.gradle`)

The `generateGoogleServices` Gradle task:
- Searches for `.env` by walking up from `android/app/` to repo root
- Reads key=value pairs from `.env`
- Environment variables (CI) take precedence over `.env` values
- Generates `android/app/google-services.json` with the values
- Runs automatically before `preBuild` (via `preBuild.dependsOn generateGoogleServices`)

**Used environment variables:**
- `FIREBASE_PROJECT_NUMBER`
- `FIREBASE_DATABASE_URL`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MOBILE_APP_ID` (fallback for soccer)
- `FIREBASE_MOBILE_APP_ID_SOCCER`
- `FIREBASE_MOBILE_APP_ID_BASKETBALL`
- `API_KEY`
- `OAUTH_CLIENT_IDS` (comma-separated)
- `IOS_APPINVITE_CLIENT_ID`
- `ANDROID_PACKAGE_NAME` (fallback for soccer)
- `ANDROID_PACKAGE_NAME_SOCCER`
- `ANDROID_PACKAGE_NAME_BASKETBALL`

**Generated file:** `android/app/google-services.json` (gitignored)

#### iOS (`ios/scripts/generate_google_service_info.sh`)

The shell script:
- Searches for `.env` by walking up from `ios/` to repo root
- Parses key=value pairs from `.env`
- Generates `ios/Runner/GoogleService-Info.plist` with the values
- Runs as an Xcode build phase (before compilation)

**Used environment variables:**
- `IOS_CLIENT_ID`
- `IOS_REVERSED_CLIENT_ID`
- `IOS_ANDROID_CLIENT_ID`
- `IOS_API_KEY`
- `FIREBASE_PROJECT_NUMBER` (as GCM_SENDER_ID)
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `IOS_BUNDLE_ID`
- `IOS_GOOGLE_APP_ID`
- `FIREBASE_DATABASE_URL`

**Generated file:** `ios/Runner/GoogleService-Info.plist` (gitignored)

#### Dart/Flutter (`lib/firebase_options.dart`)

Uses `flutter_dotenv` to read `.env` at runtime initialization:
- Loads `.env` in `main_soccer.dart` (and other entry points) via `dotenv.load()`
- `firebase_options.dart` reads values using `dotenv.env[key]`
- Throws `StateError` if required keys are missing

**Used environment variables:**
- Android: `API_KEY`, `FIREBASE_MOBILE_APP_ID`, `MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_DATABASE_URL`, `FIREBASE_STORAGE_BUCKET`
- iOS: `IOS_API_KEY`, `IOS_GOOGLE_APP_ID`, `MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_DATABASE_URL`, `FIREBASE_STORAGE_BUCKET`, `IOS_ANDROID_CLIENT_ID`, `IOS_CLIENT_ID`, `IOS_BUNDLE_ID`
- Web: `WEB_API_KEY`, `WEB_APP_ID`, `MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `WEB_AUTH_DOMAIN`, `FIREBASE_DATABASE_URL`, `FIREBASE_STORAGE_BUCKET`, `WEB_MEASUREMENT_ID`

## Setup Instructions

### Local Development

1. **Create `.env` file** in the repo root:
   ```bash
   cp .env.example .env  # if you have a template
   # or manually create .env
   ```

2. **Populate with your Firebase values:**
   ```bash
   # .env (never commit this file)
   FIREBASE_PROJECT_NUMBER=542457934179
   FIREBASE_DATABASE_URL=https://team-sync-soccer-default-rtdb.firebaseio.com
   FIREBASE_PROJECT_ID=team-sync-soccer
   FIREBASE_STORAGE_BUCKET=team-sync-soccer.firebasestorage.app
   FIREBASE_MOBILE_APP_ID=1:542457934179:android:fc3f9989d51f9e2cc52356
   API_KEY=AIzaSy...
   # ... etc
   ```

3. **Verify `.gitignore` includes `.env`:**
   ```gitignore
   .env
   .env.*
   ```

4. **Build the project:**
   ```bash
   # Android
   cd android && ./gradlew :app:generateGoogleServices

   # iOS
   cd ios && xcodebuild -scheme Runner -configuration Debug

   # Flutter
   flutter run
   ```

### CI/CD (GitHub Actions)

Set repository secrets in GitHub:
- Settings → Secrets and variables → Actions → New repository secret

Add all variables from `.env` as GitHub secrets (same names).

In your workflow YAML:
```yaml
- name: Generate config files
  env:
    FIREBASE_PROJECT_NUMBER: ${{ secrets.FIREBASE_PROJECT_NUMBER }}
    FIREBASE_DATABASE_URL: ${{ secrets.FIREBASE_DATABASE_URL }}
    # ... all other secrets
  run: |
    cd android && ./gradlew :app:generateGoogleServices
```

**Environment variables take precedence** over `.env` files, so CI will use GitHub Secrets.

## Files Generated at Compile Time

These files are **gitignored** and generated from `.env`:

- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

**Do not commit these files.** They are recreated on every build.

## Security Best Practices

✅ **DO:**
- Keep `.env` out of version control (in `.gitignore`)
- Use different `.env` files for dev/staging/prod environments
- Rotate API keys if they are ever exposed
- Use restricted API keys (with platform/domain/IP restrictions)
- Store production secrets in CI/CD secrets manager (GitHub Secrets, etc.)

❌ **DON'T:**
- Commit `.env` or `.env.*` files
- Hardcode secrets in source code
- Share `.env` files via email/Slack
- Use production keys in development

## Troubleshooting

### "Missing required environment variable" error

**Cause:** `.env` file is missing or doesn't have the required key.

**Fix:**
1. Ensure `.env` exists in repo root
2. Check the key is present: `grep KEY_NAME .env`
3. Verify no leading/trailing spaces in key names
4. Rebuild: `flutter clean && flutter run`

### `google-services.json` not generated

**Cause:** Gradle task didn't run or `.env` not found.

**Fix:**
```bash
cd android
./gradlew :app:generateGoogleServices --info
# Check output for .env path and errors
```

### `GoogleService-Info.plist` not generated (iOS)

**Cause:** Build script didn't run or `.env` not found.

**Fix:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Check Build Phases → "Generate GoogleService-Info.plist" script
3. Build and check logs for script output

### CI build fails with missing secrets

**Cause:** GitHub Secrets not configured.

**Fix:**
1. Go to repo Settings → Secrets and variables → Actions
2. Add all secrets from `.env` (use same key names)
3. Update workflow to export them as environment variables

## Related Files

- `.env` - Local secrets (gitignored)
- `.gitignore` - Ensures `.env` is never committed
- `android/app/build.gradle` - Contains `generateGoogleServices` task
- `ios/scripts/generate_google_service_info.sh` - iOS config generator
- `lib/firebase_options.dart` - Dart Firebase options reader
- `lib/main_soccer.dart` - Loads `.env` via `dotenv.load()`
- `pubspec.yaml` - Includes `flutter_dotenv` dependency

## Example .env Template

```bash
# Firebase Project
FIREBASE_PROJECT_NUMBER=542457934179
FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app

# Android
FIREBASE_MOBILE_APP_ID=1:542457934179:android:xxx
ANDROID_PACKAGE_NAME=com.yourcompany.yourapp
API_KEY=AIzaSy...

# OAuth Client IDs (comma-separated)
OAUTH_CLIENT_IDS=542457934179-xxx.apps.googleusercontent.com,542457934179-yyy.apps.googleusercontent.com

# iOS
IOS_CLIENT_ID=542457934179-xxx.apps.googleusercontent.com
IOS_REVERSED_CLIENT_ID=com.googleusercontent.apps.542457934179-xxx
IOS_ANDROID_CLIENT_ID=542457934179-yyy.apps.googleusercontent.com
IOS_API_KEY=AIzaSy...
IOS_GOOGLE_APP_ID=1:542457934179:ios:xxx
IOS_BUNDLE_ID=com.yourcompany.yourapp
IOS_APPINVITE_CLIENT_ID=542457934179-zzz.apps.googleusercontent.com

# Web
WEB_API_KEY=AIzaSy...
WEB_APP_ID=1:542457934179:web:xxx
MESSAGING_SENDER_ID=542457934179
WEB_AUTH_DOMAIN=your-project.firebaseapp.com
WEB_MEASUREMENT_ID=G-XXXXXXXXXX
```

