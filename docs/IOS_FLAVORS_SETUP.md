# iOS Flavors Setup Guide

## Overview
This guide explains how to set up iOS schemes (flavors) to build TeamSync and ClubSync as separate apps, similar to how Android flavors work.

## Current Status
- ✅ Android has flavors configured (teamSync, clubSync)
- ❌ iOS does NOT have schemes/flavors configured yet
- ⚠️ Both build scripts target the same iOS app currently

## What You Need to Do in Xcode

### Step 1: Open the Project
```bash
open ios/Runner.xcworkspace
```

### Step 2: Duplicate the Runner Scheme
1. In Xcode menu: **Product > Scheme > Manage Schemes...**
2. Select "Runner" scheme
3. Click the **gear icon** at bottom → **Duplicate**
4. Rename to "TeamSync"
5. Click **Duplicate** again on the original "Runner"
6. Rename to "ClubSync"
7. Delete the original "Runner" scheme (optional, but cleaner)

### Step 3: Create Build Configurations
1. Select the **Runner** project in the Project Navigator
2. Select the **Runner** target
3. Click on **Info** tab
4. Under **Configurations**, duplicate each configuration:
   - Duplicate **Debug** → **Debug-TeamSync** and **Debug-ClubSync**
   - Duplicate **Release** → **Release-TeamSync** and **Release-ClubSync**
   - Duplicate **Profile** → **Profile-TeamSync** and **Profile-ClubSync**

### Step 4: Configure TeamSync Scheme
1. **Product > Scheme > Edit Scheme...** (select TeamSync)
2. For each section (Run, Test, Profile, Analyze, Archive):
   - Set Build Configuration to use the TeamSync variant:
     - Run: **Debug-TeamSync**
     - Test: **Debug-TeamSync**
     - Profile: **Profile-TeamSync**
     - Analyze: **Debug-TeamSync**
     - Archive: **Release-TeamSync**

### Step 5: Configure ClubSync Scheme
1. **Product > Scheme > Edit Scheme...** (select ClubSync)
2. For each section, use ClubSync configurations:
   - Run: **Debug-ClubSync**
   - Test: **Debug-ClubSync**
   - Profile: **Profile-ClubSync**
   - Analyze: **Debug-ClubSync**
   - Archive: **Release-ClubSync**

### Step 6: Set Bundle Identifiers
1. Select **Runner** target → **Build Settings**
2. Search for "Product Bundle Identifier"
3. For **Debug-TeamSync**, **Profile-TeamSync**, **Release-TeamSync**:
   - Set to: `com.tsquared.team_sync.soccer`
4. For **Debug-ClubSync**, **Profile-ClubSync**, **Release-ClubSync**:
   - Set to: `com.tsquared.clubsync.soccer`

### Step 7: Set Display Names (Optional)
1. Create `Info-TeamSync.plist` and `Info-ClubSync.plist` in `ios/Runner/`
2. Or use build settings to set `PRODUCT_NAME`:
   - TeamSync configs: `TeamSync`
   - ClubSync configs: `ClubSync`

### Step 8: Configure Signing
For each configuration (TeamSync and ClubSync):
1. Select **Runner** target → **Signing & Capabilities**
2. Switch between configurations using the dropdown
3. Enable "Automatically manage signing"
4. Select your Team
5. Ensure provisioning profiles are generated for both bundle IDs

## Alternative: Use Xcode Configuration Files

Create `ios/Flutter/TeamSync.xcconfig` and `ios/Flutter/ClubSync.xcconfig`:

**TeamSync.xcconfig:**
```xcconfig
#include "Release.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.tsquared.team_sync.soccer
PRODUCT_NAME = TeamSync
DISPLAY_NAME = TeamSync
```

**ClubSync.xcconfig:**
```xcconfig
#include "Release.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.tsquared.clubsync.soccer
PRODUCT_NAME = ClubSync
DISPLAY_NAME = ClubSync
```

Then in Xcode, assign these config files to the respective build configurations.

## Verification

After setup, you should be able to:
1. Build TeamSync: `flutter build ios --flavor teamSync --target lib/main_team_sync.dart`
2. Build ClubSync: `flutter build ios --flavor clubSync --target lib/main_club_sync.dart`

## App Store Connect

Remember to:
1. Create separate App Store Connect entries for each app
2. Use different bundle identifiers
3. Set up separate provisioning profiles
4. Configure different capabilities if needed

## Firebase Configuration

You'll need separate Firebase projects/apps for iOS:
1. TeamSync: `GoogleService-Info.plist` (or `GoogleService-Info-TeamSync.plist`)
2. ClubSync: `GoogleService-Info-ClubSync.plist`

Use build phases or schemes to copy the correct file during build.

---

**Note**: This is a manual process in Xcode. Once configured, commit the `.xcscheme` files to version control so team members get the same setup.

