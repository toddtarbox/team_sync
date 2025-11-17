#!/bin/bash
# Build TeamSync app (single-team management)

set -e

echo "🏗️  Building TeamSync (Single-Team Management)..."

# Set app name
APP_NAME="TeamSync"
BUNDLE_ID="com.tsquared.team_sync.soccer"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables from .env file for web builds
ENV_FILE="$PROJECT_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Build for specified platform
PLATFORM=${1:-"all"}

case $PLATFORM in
  web)
    echo "📦 Building for Web..."
    flutter build web \
      --target=lib/main_team_sync.dart \
      --release \
      --base-href=/ \
      --dart-define=WEB_API_KEY="$WEB_API_KEY" \
      --dart-define=WEB_APP_ID="$WEB_APP_ID" \
      --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
      --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
      --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
      --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
      --dart-define=WEB_AUTH_DOMAIN="$WEB_AUTH_DOMAIN" \
      --dart-define=WEB_MEASUREMENT_ID="$WEB_MEASUREMENT_ID"
    echo "✅ Web build complete: build/web/"
    ;;

  ios)
    echo "📱 Building for iOS..."
    flutter build ios \
      --target=lib/main_team_sync.dart \
      --release \
      --no-codesign
    echo "✅ iOS build complete"
    ;;

  android)
    echo "🤖 Building for Android..."
    flutter build appbundle \
      --target=lib/main_team_sync.dart \
      --release \
      --flavor teamSync
    echo "✅ Android build complete: build/app/outputs/bundle/teamSyncRelease/"
    ;;

  all)
    echo "📦 Building for all platforms..."

    # Web
    flutter build web \
      --target=lib/main_team_sync.dart \
      --release \
      --base-href=/ \
      --dart-define=WEB_API_KEY="$WEB_API_KEY" \
      --dart-define=WEB_APP_ID="$WEB_APP_ID" \
      --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
      --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
      --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
      --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
      --dart-define=WEB_AUTH_DOMAIN="$WEB_AUTH_DOMAIN" \
      --dart-define=WEB_MEASUREMENT_ID="$WEB_MEASUREMENT_ID"

    # Android
    flutter build appbundle \
      --target=lib/main_team_sync.dart \
      --release \
      --flavor teamSync

    echo "✅ All builds complete"
    echo "   Web: build/web/"
    echo "   Android: build/app/outputs/bundle/teamSyncRelease/"
    ;;

  *)
    echo "❌ Unknown platform: $PLATFORM"
    echo "Usage: $0 [web|ios|android|macos|all]"
    exit 1
    ;;
esac

echo ""
echo "🎉 TeamSync build completed successfully!"

