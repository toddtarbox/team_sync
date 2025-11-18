# iOS IPA Build Guide

## Overview
The build scripts now produce IPA files ready for distribution via App Store Connect, TestFlight, or Ad Hoc distribution.

## Build Commands

### TeamSync
```bash
./scripts/build-team-sync.sh ios
```

Output: `build/ios/ipa/TeamSync.ipa`

### ClubSync
```bash
./scripts/build-club-sync.sh ios
```

Output: `build/ios/ipa/ClubSync.ipa`

## Export Options

Three export options files are available for different distribution methods:

### 1. App Store Distribution (Default)
**File**: `ios/ExportOptions.plist`

Used for:
- Uploading to App Store Connect
- TestFlight distribution
- Final App Store release

Build command:
```bash
flutter build ipa \
  --target=lib/main_team_sync.dart \
  --release \
  --flavor teamSync \
  --export-options-plist=ios/ExportOptions.plist
```

### 2. Ad Hoc Distribution
**File**: `ios/ExportOptions-AdHoc.plist`

Used for:
- Beta testing on registered devices
- Internal distribution to specific testers
- Requires devices to be registered in Apple Developer portal

Build command:
```bash
flutter build ipa \
  --target=lib/main_team_sync.dart \
  --release \
  --flavor teamSync \
  --export-options-plist=ios/ExportOptions-AdHoc.plist
```

### 3. Development Distribution
**File**: `ios/ExportOptions-Development.plist`

Used for:
- Testing on your own development devices
- Quick internal testing
- Debugging signed builds

Build command:
```bash
flutter build ipa \
  --target=lib/main_team_sync.dart \
  --release \
  --flavor teamSync \
  --export-options-plist=ios/ExportOptions-Development.plist
```

## Prerequisites

Before building IPA files, ensure:

1. ✅ **iOS Schemes Configured** (see `docs/IOS_FLAVORS_SETUP.md`)
   - teamSync scheme for TeamSync
   - clubSync scheme for ClubSync

2. ✅ **Code Signing Configured**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your Apple Developer Team
   - Ensure provisioning profiles are generated

3. ✅ **Apple Developer Account**
   - Active Apple Developer Program membership ($99/year)
   - Team ID configured in Xcode

4. ✅ **Bundle Identifiers Registered**
   - `com.tsquared.team_sync.soccer` (TeamSync)
   - `com.tsquared.clubsync.soccer` (ClubSync)

5. ✅ **Provisioning Profiles**
   - App Store profile for each bundle ID
   - (Optional) Ad Hoc profile for testing
   - (Optional) Development profile

## Customizing Export Options

### Adding Team ID
Edit `ios/ExportOptions.plist` and uncomment:
```xml
<key>teamID</key>
<string>YOUR_TEAM_ID_HERE</string>
```

Find your Team ID at: https://developer.apple.com/account

### Manual Signing
If using manual provisioning profiles, edit the plist:
```xml
<key>signingStyle</key>
<string>manual</string>

<key>provisioningProfiles</key>
<dict>
  <key>com.tsquared.team_sync.soccer</key>
  <string>TeamSync App Store Profile Name</string>
  <key>com.tsquared.clubsync.soccer</key>
  <string>ClubSync App Store Profile Name</string>
</dict>
```

## Uploading to App Store Connect

### Using Xcode
```bash
# Build the IPA
./scripts/build-team-sync.sh ios

# Upload via Xcode
open build/ios/ipa/
# Right-click the IPA → Open With → Transporter
# Or drag to Xcode → Window → Organizer → Distribute App
```

### Using Transporter App
1. Build the IPA: `./scripts/build-team-sync.sh ios`
2. Open Transporter app (from Mac App Store)
3. Sign in with Apple ID
4. Drag IPA file to Transporter
5. Click "Deliver"

### Using Command Line
```bash
# Install xcrun if needed (part of Xcode Command Line Tools)
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/TeamSync.ipa \
  --username your-apple-id@email.com \
  --password your-app-specific-password
```

## Troubleshooting

### "Scheme not found" Error
**Problem**: iOS schemes not configured in Xcode
**Solution**: Follow `docs/IOS_FLAVORS_SETUP.md` to create schemes

### "Code signing failed" Error
**Problem**: Missing or invalid provisioning profiles
**Solution**: 
1. Open Xcode
2. Select Runner target
3. Signing & Capabilities → "Automatically manage signing"
4. Clean build folder: Product → Clean Build Folder
5. Try build again

### "Bundle identifier mismatch" Error
**Problem**: Bundle ID in Xcode doesn't match provisioning profile
**Solution**: Verify bundle IDs in Xcode Build Settings match:
- TeamSync: `com.tsquared.team_sync.soccer`
- ClubSync: `com.tsquared.clubsync.soccer`

### IPA File Not Created
**Problem**: Build succeeded but no IPA file
**Solution**: Check `build/ios/archive/` for the xcarchive, then:
```bash
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
```

## Build Output Location

All IPA files are created in:
```
build/ios/ipa/
├── TeamSync.ipa          (TeamSync app)
├── ClubSync.ipa          (ClubSync app)
└── DistributionSummary.plist
```

## Version Management

### Updating Version Number
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # 1.0.0 is version, +1 is build number
```

### Build Number for App Store
Each App Store submission must have a unique build number:
```yaml
version: 1.0.0+2  # Increment build number for each submission
```

## Testing Your IPA

### Install on Device via Xcode
1. Connect device via USB
2. Open Xcode
3. Window → Devices and Simulators
4. Drag IPA to device

### Install via TestFlight
1. Upload IPA to App Store Connect
2. Add internal/external testers
3. Testers install via TestFlight app

### Install Ad Hoc via Direct Download
1. Host IPA file on secure server
2. Create manifest.plist (for wireless installation)
3. Share link with testers

---

**Need Help?** See `docs/IOS_FLAVORS_SETUP.md` for iOS scheme configuration

