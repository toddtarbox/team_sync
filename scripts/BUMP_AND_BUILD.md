# Bump and Build Script

Automatically bump the version/build number in `pubspec.yaml` and kick off Android and iOS builds simultaneously.

## Usage

```bash
./scripts/bump-and-build.sh [major|minor|patch|build-only]
```

### Bump Types

- **major** - Bump major version (e.g., 1.7.9 → 2.0.0+77)
- **minor** - Bump minor version (e.g., 1.7.9 → 1.8.0+77)
- **patch** - Bump patch version (e.g., 1.7.9 → 1.7.10+77) **[DEFAULT]**
- **build-only** - Only increment build number (e.g., 1.7.9+76 → 1.7.9+77)

### Examples

```bash
# Bump patch version (default) - most common for bug fixes
./scripts/bump-and-build.sh

# Bump minor version - for new features
./scripts/bump-and-build.sh minor

# Bump major version - for breaking changes
./scripts/bump-and-build.sh major

# Only bump build number - for rebuild with no code changes
./scripts/bump-and-build.sh build-only
```

## What the Script Does

1. **Reads current version** from `pubspec.yaml`
2. **Bumps version** according to specified type
3. **Increments build number** automatically
4. **Prompts for confirmation** before making changes
5. **Updates pubspec.yaml** with new version
6. **Optionally creates git commit** for the version bump
7. **Kicks off Android and iOS builds simultaneously** in parallel
8. **Logs build output** to `build/logs/` directory
9. **Shows summary** of build results
10. **Optionally deploys** to TestFlight (iOS) and Google Play Internal Test Track (Android)

## Build Outputs

After successful builds, you'll find:

- **Android**: `build/app/outputs/bundle/teamSyncRelease/`
- **iOS**: `build/ios/ipa/`
- **Build logs**: `build/logs/android_TIMESTAMP.log` and `build/logs/ios_TIMESTAMP.log`

## Requirements

- Flutter SDK installed and in PATH
- For iOS builds: Xcode with proper code signing configured
- For Android builds: Android SDK configured

## Version Numbering

Follows semantic versioning:
- **MAJOR.MINOR.PATCH+BUILD**
- Example: `1.7.9+76`
  - Major: 1
  - Minor: 7
  - Patch: 9
  - Build: 76

## Interactive Prompts

The script will ask:
1. Confirm version bump before proceeding
2. Whether to create a git commit (optional)
3. Whether to deploy to TestFlight and Google Play after successful builds (optional)

## Deployment

After successful builds, the script will optionally deploy to:
- **TestFlight** (iOS) - For internal and external testing
- **Google Play Internal Test Track** (Android) - For internal testing

### Setting Up Deployment

#### TestFlight (iOS)

1. Set environment variables:
   ```bash
   export APPLE_ID='your@email.com'
   export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'
   ```
   
2. Generate an app-specific password:
   - Go to [appleid.apple.com](https://appleid.apple.com)
   - Sign in and go to Security section
   - Generate an app-specific password
   - Save it for use in deployment

3. The script will upload your IPA to TestFlight automatically

#### Google Play Internal Test Track (Android)

1. Create a Google Cloud service account:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a service account and download the JSON key

2. Grant permissions in Google Play Console:
   - Go to [Google Play Console](https://play.google.com/console)
   - Click **Settings** (gear icon in left sidebar) → **API access**
   - Click "Link" to connect your Google Cloud project (if needed)
   - Find your service account and click "Grant access"
   - Choose **Release manager** or **Release on internal testing track only**
   - Select your app under "App permissions"

2. Save the key file:
   ```bash
   # Save to android/play-service-account.json
   # Make sure this file is in .gitignore!
   ```

3. Install Python dependencies:
   ```bash
   pip3 install google-api-python-client google-auth-httplib2 google-auth-oauthlib
   ```

4. The script will automatically upload your AAB to the Internal Test Track

### Manual Deployment

You can also deploy builds manually without bumping version:

```bash
# Deploy both iOS and Android
./scripts/deploy-mobile.sh all

# Deploy only iOS to TestFlight
./scripts/deploy-mobile.sh ios

# Deploy only Android to Google Play
./scripts/deploy-mobile.sh android
```

## Error Handling

- If either build fails, the script will report which one failed
- Build logs are saved for debugging
- Script exits with error code if builds fail

## Tips

- Use `patch` for bug fixes
- Use `minor` for new features
- Use `major` for breaking changes
- Use `build-only` when rebuilding without code changes
- Set up deployment credentials once to enable automatic uploads
- For first-time deployment setup, see the Deployment section above

## Troubleshooting

### TestFlight Upload Fails

- Ensure your Apple ID and app-specific password are correct
- Check that your app is registered in App Store Connect
- Verify code signing certificates are properly configured
- Check [App Store Connect](https://appstoreconnect.apple.com) for processing status

### Google Play Upload Fails

- Verify service account JSON file exists and has correct permissions
- Ensure service account has "Release manager" or "Release on internal testing track only" permission in Google Play Console (not Google Cloud IAM)
- Go to Google Play Console → Settings (gear icon) → API access to verify permissions
- Check that the package name matches your app
- Install required Python packages: `pip3 install google-api-python-client google-auth-httplib2 google-auth-oauthlib`
- Verify at [Google Play Console](https://play.google.com/console)

