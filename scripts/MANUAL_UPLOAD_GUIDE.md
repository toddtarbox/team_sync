# Manual Upload to Google Play Internal Testing

## Quick Guide - No API Access Needed!

If you're having trouble with Google Play Console API access, you can upload builds manually. This is actually very simple and works immediately.

---

## Step 1: Build Your App

```bash
cd /Users/toddtarbox/development/tsquared/team_sync
./scripts/build-team-sync.sh android
```

This creates: `build/app/outputs/bundle/teamSyncRelease/app-teamSync-release.aab`

---

## Step 2: Upload to Google Play Console

### A. Go to Your App

1. Visit: https://play.google.com/console
2. Click on your **TeamSync** app

### B. Navigate to Internal Testing

Look for these in the left sidebar or top tabs:
- Click **"Release"** (or **"Production"**, **"Testing"**, etc.)
- Then click **"Testing"**
- Then click **"Internal testing"**

Alternative paths depending on your interface:
- **Testing** → **Internal testing**
- **Release** → **Testing tracks** → **Internal testing**
- **Release management** → **Internal testing**

### C. Create Release

1. Click **"Create new release"** or **"Create release"** button
2. You'll see "App bundles and APKs to add" section
3. Click **"Upload"** button

### D. Select Your Build

1. Click **"Choose file"** or drag and drop
2. Navigate to:
   ```
   /Users/toddtarbox/development/tsquared/team_sync/build/app/outputs/bundle/teamSyncRelease/
   ```
3. Select: `app-teamSync-release.aab`
4. Wait for upload (you'll see a progress bar)
5. Once uploaded, you'll see the version code displayed

### E. Add Release Notes

In the "Release notes" section:
- Click **"Add release notes"** if needed
- Enter text like:
  ```
  Version 1.7.10
  - Bug fixes and performance improvements
  ```

### F. Review and Publish

1. Scroll down and click **"Review release"**
2. Review the information
3. Click **"Start rollout to Internal testing"**
4. Confirm by clicking **"Rollout"** in the dialog

---

## Step 3: Test Your Build

### Add Internal Testers (If Needed)

1. In the **Internal testing** page, scroll to "Testers" section
2. Click **"Create email list"** or use existing list
3. Add tester emails
4. Save the list

### Share with Testers

- Testers will receive an email with opt-in link
- Or share the opt-in URL shown in the "Testers" section
- Format: `https://play.google.com/apps/internaltest/...`

### Testers Download

1. Testers click the opt-in link
2. Accept to become a tester
3. Go to Google Play Store
4. Search for your app or use the direct link
5. Install the internal test version

---

## How Long Does It Take?

- ✅ Upload: 1-5 minutes
- ✅ Processing: Usually instant to 2 minutes
- ✅ Available to testers: Immediately after processing

Much faster than production releases!

---

## Version Management

### Before Building

Update version in `pubspec.yaml`:
```bash
# Use the bump-and-build script
./scripts/bump-and-build.sh patch

# When asked "Deploy?", say 'n' for now
# Then upload manually
```

### Track Your Versions

Each build has:
- **Version name**: e.g., `1.7.10` (what users see)
- **Version code**: e.g., `77` (internal number, auto-increments)

Google Play requires version code to always increase.

---

## Troubleshooting

### "You uploaded an APK or Android App Bundle that was signed in debug mode"
- ❌ Don't use debug builds
- ✅ Use: `./scripts/build-team-sync.sh android` (creates release build)

### "You need to use a different version code"
- Version code must be higher than previous release
- Use `./scripts/bump-and-build.sh build-only` to increment

### "Upload button disabled"
- Make sure you clicked "Create new release" first
- Check you're in the right track (Internal testing)

### Can't find "Internal testing"
- Look under: Release → Testing → Internal testing
- Or: Testing → Internal testing
- Create internal testing track if it doesn't exist

### Upload stuck/fails
- Check file size (should be ~50-150 MB typically)
- Ensure good internet connection
- Try a different browser
- Clear browser cache

---

## Comparing Manual vs Automated

### Manual Upload (What you're doing now)
**Pros:**
- ✅ Works immediately, no setup
- ✅ No API configuration needed
- ✅ Visual interface, easy to understand
- ✅ Can add detailed release notes

**Cons:**
- ❌ Takes a few minutes each time
- ❌ Need to navigate through web interface
- ❌ Can't automate in scripts

### Automated Upload (After API access setup)
**Pros:**
- ✅ One command deployment
- ✅ Can include in CI/CD
- ✅ Faster for frequent releases

**Cons:**
- ❌ Requires API access setup (which you're having trouble with)
- ❌ More complex initial configuration

**Recommendation:** Use manual upload for now. It's perfectly fine for weekly/monthly releases!

---

## Complete Workflow Example

Here's your complete release workflow:

```bash
# 1. Bump version and build
cd /Users/toddtarbox/development/tsquared/team_sync
./scripts/bump-and-build.sh patch

# When asked "Create git commit?", answer 'y'
# When asked "Deploy?", answer 'n' (we'll do it manually)

# 2. Builds complete, now upload manually:
# - iOS: Open Xcode Organizer → Upload to App Store Connect
# - Android: Follow the manual upload steps above

# 3. Push git changes
git push

# Done!
```

---

## Need More Help?

- **Can't find your app**: Make sure it's created in Google Play Console
- **First time setup**: You need to create the app entry first
- **Internal testing not available**: Create the track first
- **API access for automation**: See `scripts/GOOGLE_PLAY_API_ACCESS_GUIDE.md`

---

## Bottom Line

**Don't worry about API access for now.** Manual upload works great and only takes 2-3 minutes. Many development teams use manual uploads for months or years without issues.

The automated deployment is nice-to-have, not need-to-have! 🎉

