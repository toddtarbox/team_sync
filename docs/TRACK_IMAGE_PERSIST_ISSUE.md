# TRACKING: Image Not Persisting Issue

## Current Status: DEBUG MODE ENABLED ✅

### What Was Done

Added comprehensive debug output to track the imageUrl through the entire save and display process.

### Debug Output Locations

**1. When Saving (in dialog):**
```
=== Saving Accomplishment ===
Title: [title]
ImageUrl: [url or null]
ImageUrl isEmpty: [true/false]
ImageUrl after check: [url or null]
Accomplishment imageUrl: [url or null]
Accomplishment toMap: {...}
```

**2. When Displaying (in card):**
```
Building card for: [title]
Card imageUrl: [url or null]
Card imageUrl isNotEmpty: [true/false]
```

## How to Debug

### Step 1: Run in Debug Mode
```bash
flutter run --debug
```

### Step 2: Test Image Upload
1. Open accomplishment dialog
2. Pick an image from gallery
3. Wait for "Uploading..." to complete
4. Fill in required fields (title)
5. Tap Save

### Step 3: Check Console Output

Look for the debug messages in this sequence:

**During Upload:**
- Image picker opens
- "Uploading..." shows
- Image preview appears

**During Save:**
```
=== Saving Accomplishment ===
Title: State Champions
ImageUrl: https://firebasestorage.googleapis.com/v0/b/.../accomplishment_images/1732800000000.jpg
ImageUrl isEmpty: false
ImageUrl after check: https://firebasestorage.googleapis.com/...
Accomplishment imageUrl: https://firebasestorage.googleapis.com/...
Accomplishment toMap: {id: 1732800000000, teamId: 1, title: State Champions, description: null, imageUrl: https://firebasestorage.googleapis.com/..., url: null, year: 2024, displayOrder: 0}
```

**During Display:**
```
Building card for: State Champions
Card imageUrl: https://firebasestorage.googleapis.com/...
Card imageUrl isNotEmpty: true
```

## Diagnostic Scenarios

### Scenario A: imageUrl is null when saving
**Debug shows:**
```
ImageUrl: null
```

**Problem:** Image upload failed or setState didn't update variable

**Check:**
- Look for Firebase Storage errors before this
- Verify storage rules are deployed
- Check if upload success callback ran

### Scenario B: imageUrl is correct when saving but null when displaying
**Debug shows:**
```
Saving: ImageUrl: https://...
Displaying: Card imageUrl: null
```

**Problem:** Data not persisting to database or not reloading correctly

**Check:**
- Verify TeamAccomplishment.save() completed without errors
- Check if setState is updating _accomplishments list
- Verify database has the imageUrl field

### Scenario C: imageUrl is correct everywhere but image not visible
**Debug shows:**
```
Saving: ImageUrl: https://...
Displaying: Card imageUrl: https://...
Card imageUrl isNotEmpty: true
```

**Problem:** Image widget error or network issue

**Check:**
- Look for Image.network error logs
- Verify URL is accessible
- Check if error builder is being triggered

## Expected vs Actual

### Expected Flow:
1. Upload image ✅ (Storage rules fixed)
2. Get download URL ✅
3. Update local variable ✅
4. Save to database ✅
5. Update UI list ✅
6. Card displays image ✅

### Where It Might Break:
- ❓ StatefulBuilder variable scope (imageUrl)
- ❓ Database save not including imageUrl
- ❓ List update not using new object
- ❓ Card rebuild not showing new data

## Quick Verification

After running the test, answer these:

1. **Does console show imageUrl during save?**
   - Yes → Data is being prepared correctly
   - No → Upload or variable update failed

2. **Does console show imageUrl when building card?**
   - Yes → Data persisted and loaded correctly
   - No → Database or list update issue

3. **Is the image tag rendered in the card?**
   - Check if `if (accomplishment.imageUrl != null && accomplishment.imageUrl!.isNotEmpty)` branch executes

## Next Actions Based on Results

### If imageUrl is null in save output:
→ Problem is in the upload/setState phase
→ Check the upload callback and variable assignment

### If imageUrl is in save but not in card:
→ Problem is in persistence or reload
→ Check database write and list update

### If imageUrl is in card but image doesn't show:
→ Problem is in rendering
→ Check Image.network widget and URL accessibility

## Files With Debug Output

- `/lib/widgets/team_sync/team_home_page.dart` 
  - Line ~3860: Save debug output
  - Line ~3267: Card debug output

## Remove Debug Output Later

Once issue is fixed, search for:
```dart
debugPrint('=== Saving Accomplishment ===');
debugPrint('Building card for:');
```

And remove those debug blocks.

## Run The Test Now!

1. `flutter run --debug`
2. Add accomplishment with image
3. Copy console output
4. Share the output to diagnose the exact issue

The debug output will tell us exactly where the problem is! 🔍

