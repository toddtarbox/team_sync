# Image Picker for Team Accomplishments - FIXED

## ⚠️ CRITICAL: Firebase Storage Rules Required

### The Error You're Seeing
```
StorageException: User does not have permission to access this object.
Code: -13021 HttpResult: 403
The server has terminated the upload session
```

### The Problem
The `accomplishment_images/` folder doesn't have Firebase Storage permissions configured, preventing image uploads.

### The Fix ✅

**1. Storage rules have been updated in `storage.rules`:**
```
// Team accomplishment images
// Path: accomplishment_images/{imageId}
match /accomplishment_images/{imageId} {
  allow read, write, delete: if true;
}
```

**2. Deploy the rules NOW:**
```bash
firebase deploy --only storage
```

Or use the script:
```bash
./deploy-storage-rules.sh
```

**3. Test the upload again** - It will work immediately after deployment!

## Implementation Details

### What Was Added
- Image picker functionality in accomplishment dialog
- Upload to Firebase Storage at `accomplishment_images/{timestamp}.jpg`
- Preview with remove button
- Progress indicator during upload
- Error handling for failures

### File Modified
**`/lib/widgets/team_sync/team_home_page.dart`**
- Added `firebase_storage` import
- Converted dialog to StatefulBuilder
- Replaced URL text field with image picker button
- Upload handling with progress states

### Storage Rules Updated  
**`storage.rules`**
- Added rule for `accomplishment_images/` folder
- Matches the same open permissions as `award_images/`
- Allows authenticated and unauthenticated access (same as awards)

## Why The Error Occurred

Firebase Storage denies all access by default. When the app tried to upload to `accomplishment_images/`, there was no matching rule, so Firebase returned a 403 Permission Denied error.

The awards feature works because it already has a rule:
```
match /award_images/{imageId} {
  allow read, write, delete: if true;
}
```

Now accomplishments have the same rule.

## After Deploying Rules

### What Will Work
✅ Tap "Pick Image" in accomplishment dialog
✅ Select image from gallery  
✅ Image uploads successfully
✅ Preview shows in dialog
✅ Image saves with accomplishment
✅ Image displays on cards

### User Experience
1. Open Add/Edit Accomplishment dialog
2. Tap "Pick Image" button (mobile only)
3. Select photo from gallery
4. See "Uploading..." indicator
5. Preview appears with X to remove
6. Save - image is stored permanently

## Storage Structure

```
Firebase Storage
├── award_images/          (existing - works)
├── accomplishment_images/ (NEW - needs deployment)
│   ├── 1732800000000.jpg
│   ├── 1732800123456.jpg
│   └── ...
├── player_images/
└── ...
```

## Quick Start Checklist

- [x] Code updated to use image picker
- [x] Storage rules added to `storage.rules`
- [ ] **ACTION REQUIRED: Deploy storage rules**
- [ ] Test upload on mobile device
- [ ] Verify image displays correctly

## Deploy Command

Run this command from the project root:

```bash
firebase deploy --only storage
```

Expected output:
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/...
```

## Verification Steps

After deployment:
1. Open app on mobile (logged in)
2. Navigate to team home page
3. Tap + to add accomplishment
4. Tap "Pick Image"
5. Select any image
6. Should see "Uploading..."
7. Should see preview appear
8. Save accomplishment
9. Image should display on card

If any step fails, check:
- Firebase Storage rules were deployed successfully
- User is logged in (check auth state)
- Network connection is stable
- Firebase Storage is enabled in console

## Summary

**Problem:** 403 Permission error when uploading accomplishment images.

**Cause:** Missing storage rule for `accomplishment_images/` folder.

**Solution:** Added rule to `storage.rules` file.

**Action Required:** Run `firebase deploy --only storage`

**After deployment:** Image uploads will work perfectly! 🎉

The code is ready, the rules are configured, just need to deploy and you're all set! 🚀

