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
FLAVOR=${2:-"soccer"}

# Determine configuration based on flavor
if [ "$FLAVOR" == "basketball" ]; then
  TARGET="lib/main_basketball.dart"
  BUNDLE_ID="com.tsquared.team_sync.basketball"
  APP_DISPLAY_NAME="TeamSync Basketball"
else
  # Default to soccer
  TARGET="lib/main_soccer.dart"
  BUNDLE_ID="com.tsquared.team_sync.soccer"
  APP_DISPLAY_NAME="TeamSync Soccer"
fi

echo "🏗️  Building $APP_DISPLAY_NAME ($FLAVOR)..."

case $PLATFORM in
  web)
    echo "📦 Building for Web..."
    cd "$PROJECT_ROOT"
    # flutter clean # optimization: skip clean to allow incremental builds
    # flutter pub get # optimization: skip pub get, build command checks it
    echo "🔨 Building web release..."
    flutter build web \
      --target=$TARGET \
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
    echo "📱 Building iOS Archive..."
    echo "   Note: IPA export may fail due to Flutter/Xcode codesigning conflict"
    echo "   If it fails, you'll distribute via Xcode Organizer instead"
    echo ""

    flutter build ipa \
      --target=$TARGET \
      --release \
      --flavor $FLAVOR \
      --export-options-plist=ios/ExportOptions.plist

    BUILD_EXIT_CODE=$?

    if [ $BUILD_EXIT_CODE -eq 0 ]; then
      echo ""
      echo "✅ iOS IPA build complete: build/ios/ipa/"
      echo "   Ready to upload to App Store Connect!"
    else
      # Check if archive was created
      ARCHIVE_PATH="$PROJECT_ROOT/build/ios/archive/TeamSync.xcarchive"
      if [ -d "$ARCHIVE_PATH" ]; then
        echo ""
        echo "✅ Archive created successfully!"
        echo "❌ IPA export failed (codesigning issue)"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📱 Distribute via Xcode (RECOMMENDED):"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1. Opening archive in Xcode..."
        open "$ARCHIVE_PATH"
        echo ""
        echo "2. In Xcode Organizer window that just opened:"
        echo "   • Click 'Distribute App' button"
        echo "   • Select 'App Store Connect'"
        echo "   • Follow prompts to upload"
        echo ""
        echo "See IOS_IPA_EXPORT_FIX.md for details"
        echo ""
      else
        echo ""
        echo "❌ iOS build failed completely"
        echo ""
        echo "Common issues:"
        echo "  • Wrong certificate (run: ./scripts/check-ios-certs.sh)"
        echo "  • Wrong team selected in Xcode"
        echo "  • Provisioning profile issues"
        echo ""
        echo "Quick fix:"
        echo "  1. Open: open ios/Runner.xcworkspace"
        echo "  2. Runner → Signing & Capabilities → Select team YW585V7K76"
        echo ""
        exit 1
      fi
    fi
    ;;

  android)
    echo "🤖 Building for Android..."
    flutter build appbundle \
      --target=$TARGET \
      --release \
      --flavor $FLAVOR
    echo "✅ Android build complete: build/app/outputs/bundle/${FLAVOR}Release/"
    ;;

  all)
    echo "📦 Building for all platforms..."
    echo "🧹 Cleaning previous builds..."
    cd "$PROJECT_ROOT"
    flutter clean
    flutter pub get

    # Web
    echo "🔨 Building web release..."
    flutter build web \
      --target=$TARGET \
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
    echo "🔨 Building Android release..."
    flutter build appbundle \
      --target=$TARGET \
      --release \
      --flavor $FLAVOR

    echo "✅ All builds complete"
    echo "   Web: build/web/"
    echo "   Android: build/app/outputs/bundle/${FLAVOR}Release/"
    ;;

  *)
    echo "❌ Unknown platform: $PLATFORM"
    echo "Usage: $0 [web|ios|android|macos|all] [soccer|basketball]"
    exit 1
    ;;
esac

echo ""
echo "🎉 TeamSync build completed successfully!"

