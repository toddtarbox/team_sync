#!/bin/bash
# Build iOS archive and export to IPA using Xcode directly
# This bypasses the Flutter IPA export that's having codesigning issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏗️  Building iOS Archive and IPA..."
echo ""

# Step 1: Clean and build archive
echo "📦 Step 1: Building archive with Flutter..."
cd "$PROJECT_ROOT"
flutter clean
flutter pub get

flutter build ios --release --flavor teamSync --no-codesign

# Step 2: Open archive in Xcode for distribution
ARCHIVE_PATH="$PROJECT_ROOT/build/ios/archive/TeamSync.xcarchive"

if [ ! -d "$ARCHIVE_PATH" ]; then
  echo "❌ Archive not found at: $ARCHIVE_PATH"
  echo "   Build may have failed."
  exit 1
fi

echo ""
echo "✅ Archive created successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 Next Steps - Export IPA in Xcode:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Opening archive in Xcode Organizer..."
open "$ARCHIVE_PATH"

echo ""
echo "2. In Xcode Organizer:"
echo "   • Click 'Distribute App' button"
echo "   • Select 'App Store Connect'"
echo "   • Click 'Next'"
echo "   • Select 'Upload' (or 'Export' to save IPA locally)"
echo "   • Click 'Next'"
echo "   • Choose options (defaults are usually fine)"
echo "   • Click 'Upload' or 'Export'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Alternative - Use xcodebuild to export (advanced):"
echo "  xcodebuild -exportArchive \\"
echo "    -archivePath '$ARCHIVE_PATH' \\"
echo "    -exportPath '$PROJECT_ROOT/build/ios/ipa' \\"
echo "    -exportOptionsPlist '$PROJECT_ROOT/ios/ExportOptions.plist'"
echo ""

