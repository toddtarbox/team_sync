# Debugging Flutter Web Deployment

## Quick Debug Deployment

### Option 1: Deploy Debug Build to Firebase Hosting

Simply run the debug deploy script:

```bash
./scripts/deploy-web-debug.sh
```

This will:
1. Build Flutter web in debug mode with source maps
2. Deploy to Firebase Hosting
3. Show you a warning to remember to deploy production later

After deployment, open your site and check the browser console.

**Don't forget to redeploy production when done:**
```bash
./scripts/deploy-web.sh
```

### Option 2: Test Locally with Firebase Serve (Recommended)

This is faster and doesn't require deploying to production:

```bash
# Build debug version
./scripts/build-web-debug.sh

# Serve locally
firebase serve --only hosting
```

Then open http://localhost:5000 in your browser.

### Option 3: Use Firebase Emulators

```bash
# Build debug version
./scripts/build-web-debug.sh

# Start emulators (hosting + database + functions)
firebase emulators:start
```

## Debugging Tools & Techniques

### 1. Browser Developer Console

Open Chrome DevTools (F12 or Cmd+Option+I) and check:

- **Console tab**: Look for JavaScript errors and Flutter logs
- **Network tab**: Check if resources are loading (look for 404s or CORS errors)
- **Application tab**: Check if service workers are causing issues

### 2. Check Source Maps

The debug build includes `--source-maps` which lets you see Dart code in the browser:

1. Open DevTools
2. Go to Sources tab
3. Look for your Dart files (they'll be readable, not minified)

### 3. Enable Verbose Logging

Add this to your `main.dart` temporarily:

```dart
void main() async {
  // Enable debug logging
  if (kDebugMode) {
    debugPrint('Starting app...');
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... rest of your code
}
```

### 4. Check Firebase Configuration

Add logging to verify Firebase is initialized:

```dart
try {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized successfully');
} catch (e) {
  debugPrint('❌ Firebase initialization failed: $e');
}
```

### 5. Common Issues & Solutions

#### App shows blank white screen
- Check browser console for errors
- Verify `build/web/index.html` exists
- Check if service worker is cached (clear site data in DevTools)

#### Firebase not connecting
- Verify all environment variables are set correctly
- Check browser console for Firebase errors
- Test with: `firebase serve` to see detailed logs

#### CORS errors
- This usually means Firebase isn't properly configured
- Check `WEB_AUTH_DOMAIN` in your `.env`
- Verify Firebase project settings

#### 404 on assets
- Make sure `build/web` has all files
- Check Firebase hosting `public` directory is set to `build/web`

### 6. View Deployed Logs

After deploying, check the browser console on your deployed site. You can also:

```bash
# View Firebase Hosting logs
firebase hosting:logs
```

### 7. Compare Local vs Deployed

```bash
# Test locally first
./scripts/build-web-debug.sh
firebase serve --only hosting

# If it works locally but not deployed, check:
# - Environment variables in build script
# - Firebase.json configuration
# - Browser cache (try incognito mode)
```

## Production Debugging

If you need to debug the production build:

```bash
# Build production with source maps
cd /Users/toddtarbox/development/tsquared/team_sync
flutter build web --release \
  --source-maps \
  --dart-define=WEB_API_KEY="..." \
  # ... other defines
```

## Quick Checklist

Before deploying, verify:

- [ ] `.env` file has all required variables
- [ ] `firebase.json` points to correct build script
- [ ] Local serve works: `firebase serve --only hosting`
- [ ] Browser console shows no errors
- [ ] Firebase initialization succeeds
- [ ] All routes load correctly

## Getting Help

If the app still doesn't load:

1. Check browser console errors
2. Run `./scripts/build-web-debug.sh` and test locally
3. Compare network requests between local and deployed
4. Check Firebase Hosting deployment logs
5. Try deploying to a different Firebase project to isolate issues

