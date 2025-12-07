#!/bin/bash

# Deploy Flutter web DEBUG build to Firebase Hosting
# This script builds the web app in debug mode and deploys it
# Usage: ./scripts/deploy-web-debug.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏆 Deploying TeamSync DEBUG build (Team Management)..."
APP_NAME="TeamSync"
TARGET="lib/main_team_sync.dart"
HOSTING_SITE="team-sync-soccer"

echo ""
echo "🔨 Building $APP_NAME web in DEBUG mode..."
cd "$PROJECT_ROOT"
flutter build web \
  --target="$TARGET" \
  --profile \
  --source-maps \
  --base-href=/

echo ""
echo "🚀 Deploying $APP_NAME DEBUG build to Firebase hosting site: $HOSTING_SITE..."

# Ensure we're using the correct Firebase project
firebase use team-sync-soccer

firebase deploy --only hosting:$HOSTING_SITE

echo ""
echo "✅ $APP_NAME debug deployment complete!"
echo ""
echo "⚠️  WARNING: This is a DEBUG build with source maps."
echo "   Don't forget to deploy production build when done debugging:"
echo "   ./scripts/deploy-web.sh $APP_TYPE"

