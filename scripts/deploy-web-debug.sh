#!/bin/bash

# Deploy Flutter web DEBUG build to Firebase Hosting
# This script builds the web app in debug mode and deploys it
# Usage: ./scripts/deploy-web-debug.sh [team|club]
#   Arguments:
#     team - Deploy TeamSync app
#     club - Deploy ClubSync app

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if app type is provided
if [ $# -eq 0 ]; then
  echo "❌ Error: Please specify which app to deploy"
  echo ""
  echo "Usage: ./scripts/deploy-web-debug.sh [team|club]"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deploy-web-debug.sh team    # Deploy TeamSync debug build"
  echo "  ./scripts/deploy-web-debug.sh club    # Deploy ClubSync debug build"
  exit 1
fi

APP_TYPE=$1

# Validate app type and set configuration
case $APP_TYPE in
  team)
    echo "🏆 Deploying TeamSync DEBUG build (Single-Team Management)..."
    APP_NAME="TeamSync"
    TARGET="lib/main_team_sync.dart"
    HOSTING_SITE="team-sync-soccer"
    ;;
  club)
    echo "🏟️  Deploying ClubSync DEBUG build (Multi-Team Club Management)..."
    APP_NAME="ClubSync"
    TARGET="lib/main_club_sync.dart"
    HOSTING_SITE="team-sync-club-soccer"
    ;;
  *)
    echo "❌ Error: Invalid app type '$APP_TYPE'"
    echo "Must be either 'team' or 'club'"
    exit 1
    ;;
esac

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

