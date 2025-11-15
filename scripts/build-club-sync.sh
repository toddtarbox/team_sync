#!/bin/bash
# Build ClubSync app (multi-team club management)

set -e

echo "🏗️  Building ClubSync (Multi-Team Club Management)..."

# Set app name
APP_NAME="ClubSync"
BUNDLE_ID="com.tsquared.club_sync"

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
      --target=lib/main_club_sync.dart \
      --release \
      --base-href=/ \
      --dart-define=WEB_API_KEY="$WEB_API_KEY" \
      --dart-define=CLUBSYNC_WEB_APP_ID="$CLUBSYNC_WEB_APP_ID" \
      --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
      --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
      --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
      --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
      --dart-define=CLUBSYNC_WEB_AUTH_DOMAIN="$CLUBSYNC_WEB_AUTH_DOMAIN" \
      --dart-define=CLUBSYNC_WEB_MEASUREMENT_ID="$CLUBSYNC_WEB_MEASUREMENT_ID"
    echo "✅ Web build complete: build/web/"
    ;;

  ios)
    echo "📱 Building for iOS..."
    flutter build ios \
      --target=lib/main_club_sync.dart \
      --release \
      --no-codesign
    echo "✅ iOS build complete"
    ;;

  android)
    echo "🤖 Building for Android..."
    flutter build apk \
      --target=lib/main_club_sync.dart \
      --release
    echo "✅ Android build complete: build/app/outputs/flutter-apk/"
    ;;

  all)
    echo "📦 Building for all platforms..."

    # Web
    flutter build web \
      --target=lib/main_club_sync.dart \
      --release \
      --base-href=/ \
      --dart-define=WEB_API_KEY="$WEB_API_KEY" \
      --dart-define=CLUBSYNC_WEB_APP_ID="$CLUBSYNC_WEB_APP_ID" \
      --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
      --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
      --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
      --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
      --dart-define=CLUBSYNC_WEB_AUTH_DOMAIN="$CLUBSYNC_WEB_AUTH_DOMAIN" \
      --dart-define=CLUBSYNC_WEB_MEASUREMENT_ID="$CLUBSYNC_WEB_MEASUREMENT_ID"

    # Android
    flutter build apk \
      --target=lib/main_club_sync.dart \
      --release

    echo "✅ All builds complete"
    echo "   Web: build/web/"
    echo "   Android: build/app/outputs/flutter-apk/"
    ;;

  *)
    echo "❌ Unknown platform: $PLATFORM"
    echo "Usage: $0 [web|ios|android|macos|all]"
    exit 1
    ;;
esac

echo ""
echo "🎉 ClubSync build completed successfully!"

