# Firebase Deploy with Custom Build Script

This document explains how to deploy your Flutter web app to Firebase Hosting with the proper build configuration.

## Configuration

The `firebase.json` file is configured with:

### 1. **Public Directory**
```json
"public": "build/web"
```
Points to the Flutter web build output directory.

### 2. **URL Rewrites**
```json
"rewrites": [
  {
    "source": "**",
    "destination": "/index.html"
  }
]
```
Routes all requests to index.html for Flutter's client-side routing.

### 3. **Cache Headers**
Optimized caching strategy:
- HTML files: No cache (always fresh)
- Static assets (JS, CSS, images): 1 year cache

## Usage

### Deploy Production Build

Use the all-in-one deploy script that builds and deploys:

```bash
./scripts/deploy-web.sh
```

This will:
1. ✅ Run `./scripts/build-web.sh` to build Flutter web with secrets from `.env`
2. ✅ Deploy the `build/web` directory to Firebase Hosting

### Deploy Debug Build

To deploy a debuggable version with source maps:

```bash
./scripts/deploy-web-debug.sh
```

This deploys a debug build that you can inspect in browser DevTools.

⚠️ **Remember to deploy production again when done debugging!**

### Manual Deployment

If you prefer to build and deploy separately:

```bash
# Build first
./scripts/build-web.sh

# Then deploy
firebase deploy --only hosting
```

### Deploy Everything (Functions + Hosting + Database Rules)

```bash
# Build web first
./scripts/build-web.sh

# Deploy all Firebase services
firebase deploy
```


## Environment Setup

Make sure you have:
1. ✅ `.env` file with all required web secrets
2. ✅ `build-web.sh` script is executable (`chmod +x scripts/build-web.sh`)
3. ✅ Firebase CLI installed (`npm install -g firebase-tools`)
4. ✅ Logged in to Firebase (`firebase login`)

## Required Environment Variables

The build script requires these variables in `.env`:
- `WEB_API_KEY`
- `WEB_APP_ID`
- `MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_DATABASE_URL`
- `FIREBASE_STORAGE_BUCKET`
- `WEB_AUTH_DOMAIN`
- `WEB_MEASUREMENT_ID`

## Troubleshooting

### Build script not running?
Make sure it's executable:
```bash
chmod +x scripts/build-web.sh
```

### Environment variables not found?
Ensure `.env` file exists in project root with all required variables.

### Deploy fails?
Check Firebase CLI version:
```bash
firebase --version
```
Update if needed:
```bash
npm install -g firebase-tools@latest
```

## Local Testing

Before deploying, test locally:

```bash
# Build with the script
./scripts/build-web.sh

# Serve locally with Firebase
firebase serve --only hosting
```

Or use the emulator suite:
```bash
firebase emulators:start
```

