# Mobile Deployment Script

Deploy TeamSync mobile builds to TestFlight (iOS) and Google Play Internal Test Track (Android).

## Usage

```bash
./scripts/deploy-mobile.sh [ios|android|all]
```

### Examples

```bash
# Deploy both iOS and Android
./scripts/deploy-mobile.sh all

# Deploy only iOS to TestFlight
./scripts/deploy-mobile.sh ios

# Deploy only Android to Google Play Internal Test Track
./scripts/deploy-mobile.sh android
```

## Prerequisites

### TestFlight (iOS)

1. **Build the iOS app first:**
   ```bash
   ./scripts/build-team-sync.sh ios
   ```

2. **Set up Apple credentials** (one of these methods):
   
   **Option A: Environment Variables (Recommended)**
   ```bash
   export APPLE_ID='your@email.com'
   export APPLE_APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'
   ```
   
   **Option B: Manual entry**
   - The script will prompt you if credentials are not found

3. **Generate app-specific password:**
   - Go to [appleid.apple.com](https://appleid.apple.com)
   - Sign in → Security section
   - Generate an app-specific password
   - Save it securely

### Google Play Internal Test Track (Android)

1. **Build the Android app first:**
   ```bash
   ./scripts/build-team-sync.sh android
   ```

2. **Create a Google Cloud service account:**
   
   **Step 1: Create the service account in Google Cloud**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Select your project (same one linked to Google Play)
   - Navigate to IAM & Admin → Service Accounts
   - Click "Create Service Account"
   - Give it a name (e.g., "google-play-deployer")
   - Click "Create and Continue"
   - Skip the optional steps and click "Done"
   - Click on the service account you just created
   - Go to "Keys" tab → "Add Key" → "Create new key"
   - Choose JSON format and download the key file
   
   **Step 2: Link service account to Google Play Console**
   
   **METHOD 1 - Direct URL (Easiest):**
   - Go directly to: https://play.google.com/console/api-access
   - This bypasses navigation and takes you straight to API access
   
   **METHOD 2 - Via Navigation:**
   - Go to [Google Play Console](https://play.google.com/console)
   - Look for **"Settings"** in the left sidebar (gear icon ⚙️, usually at bottom)
   - Click **"API access"** in the Settings menu
   
   **METHOD 3 - Via All Applications:**
   - Go to [Google Play Console](https://play.google.com/console)
   - Click "All applications" or "All apps" in the left sidebar
   - Look for a "Developer account" or "Account" section
   - Find "API access" link
   
   **Once you're in API access:**
   - If you see "No Google Cloud project linked", click **"Link"** to connect your project
   - Under "Service accounts" section, you should see your service account email
   - Click **"Grant access"** or **"Manage Play Console permissions"** next to it
   - Select your app(s) under "App permissions"
   - Under "Account permissions", choose:
     - **"Release manager"** (recommended) - Can manage all releases
     - **"Release on internal testing track only"** - Limited to internal only
   - Click **"Invite user"** or **"Apply"** to save changes
   
   **Still can't find it?**
   - Ensure you're signed in as the **Developer Account Owner** or have Admin permissions
   - Some accounts need to have at least one published app before API access appears
   - Try the direct URL: `https://play.google.com/console/api-access`

3. **Save the service account JSON:**
   ```bash
   # Save to this location:
   android/play-service-account.json
   
   # IMPORTANT: Add to .gitignore
   echo "android/play-service-account.json" >> .gitignore
   ```

4. **Install Python dependencies:**
   ```bash
   pip3 install google-api-python-client google-auth-httplib2 google-auth-oauthlib
   ```

### ⚠️ Can't Find API Access? Use Manual Upload

If you cannot locate the API access section in Google Play Console (even as account owner), you can manually upload builds. This works immediately without any API setup:

**Manual Upload Process:**

1. **Build your app** (if not already built):
   ```bash
   ./scripts/build-team-sync.sh android
   ```

2. **Go to Google Play Console:**
   - Visit [Google Play Console](https://play.google.com/console)
   - Select your app from the list

3. **Navigate to Internal Testing:**
   - Click **"Release"** in the left sidebar (or top tabs)
   - Click **"Testing"** or expand the Release section
   - Click **"Internal testing"**

4. **Create a new release:**
   - Click **"Create new release"** button
   - Under "App bundles and APKs", click **"Upload"**
   - Select the AAB file from:
     ```
     build/app/outputs/bundle/teamSyncRelease/app-teamSync-release.aab
     ```
   - Wait for upload to complete (shows version code when done)

5. **Add release notes:**
   - Enter what's new in this version
   - Example: "Bug fixes and improvements"

6. **Review and rollout:**
   - Click **"Review release"**
   - Click **"Start rollout to Internal testing"**
   - Confirm the rollout

**That's it!** Your build will be available to internal testers within minutes.

**Note:** While manual upload works great, automated deployment is more convenient for frequent releases. If you'd like help troubleshooting the API access issue, see `scripts/GOOGLE_PLAY_API_ACCESS_GUIDE.md`.

## What the Script Does

### iOS Deployment
1. Verifies IPA file exists
2. Checks for Apple credentials
3. Uploads IPA to App Store Connect using `xcrun altool`
4. Build will appear in TestFlight after Apple processes it

### Android Deployment
1. Verifies AAB file exists
2. Checks for service account JSON
3. Creates/uses Python upload script
4. Uploads AAB to Google Play Internal Test Track via API
5. Build will be available to internal testers immediately

## Environment Variables

### iOS
- `APPLE_ID` - Your Apple ID email
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password from appleid.apple.com

### Android
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` - Path to service account JSON (optional)
  - Default: `android/play-service-account.json`

## Integration with bump-and-build.sh

The `bump-and-build.sh` script automatically offers to deploy after successful builds:

```bash
# Bump version, build, and optionally deploy
./scripts/bump-and-build.sh patch
```

After builds complete, it will prompt:
```
Deploy to TestFlight and Google Play Internal Test Track? [y/N]:
```

## Troubleshooting

### TestFlight Upload Issues

**"Invalid credentials" error:**
- Verify your Apple ID is correct
- Ensure app-specific password is valid (not your Apple ID password)
- Generate a new app-specific password if needed

**"App not found" error:**
- Ensure your app is registered in App Store Connect
- Verify the bundle ID matches

**"Code signing" error:**
- Check Xcode code signing configuration
- Ensure proper certificates are installed

**Check upload status:**
- Visit [App Store Connect](https://appstoreconnect.apple.com)
- Go to My Apps → Your App → TestFlight
- Processing can take 5-30 minutes

### Google Play Upload Issues

**"Service account not found" error:**
```bash
# Verify file exists
ls -la android/play-service-account.json

# Check file permissions
chmod 600 android/play-service-account.json
```

**"Insufficient permissions" error:**
- Go to [Google Play Console](https://play.google.com/console)
- Click **Settings** (gear icon) in left sidebar → **API access**
- Find your service account in the list
- Click "View and edit app permissions" or the service account email
- Ensure it has one of these permissions:
  - "Release manager" (full release access)
  - "Release on internal testing track only" (internal only)
- Make sure your app is selected under "App permissions"

**"Package name mismatch" error:**
- Verify package name in script matches your app
- Default: `com.tsquared.team_sync.soccer`

**"Python module not found" error:**
```bash
# Install required packages
pip3 install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib
```

**Check upload status:**
- Visit [Google Play Console](https://play.google.com/console)
- Select your app → Release → Testing → Internal testing
- Builds appear within minutes

### General Issues

**"Build file not found" error:**
- Run the appropriate build command first:
  - iOS: `./scripts/build-team-sync.sh ios`
  - Android: `./scripts/build-team-sync.sh android`

**"bundletool not found" (Android):**
```bash
brew install bundletool
```

## Security Notes

### Protecting Credentials

**Apple Credentials:**
- Never commit app-specific passwords to git
- Use environment variables or secure storage
- Rotate app-specific passwords periodically

**Google Service Account:**
```bash
# Add to .gitignore immediately
echo "android/play-service-account.json" >> .gitignore

# Verify it's not tracked
git status android/play-service-account.json
```

- Keep service account JSON secure
- Never commit to version control
- Limit access to authorized team members only
- Use different service accounts for different environments

## Best Practices

1. **Test builds locally** before deploying
2. **Use internal tracks** for initial testing
3. **Gradual rollout** for production releases
4. **Monitor crash reports** in both consoles
5. **Keep credentials secure** and rotated regularly

## Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [Google Play Console](https://play.google.com/console)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [Google Play Console API](https://developers.google.com/android-publisher)

