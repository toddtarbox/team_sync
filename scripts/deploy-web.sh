#!/bin/bash

# Deploy Flutter web to Firebase Hosting
# This script builds the web app and deploys it in one command
# Usage: ./scripts/deploy-web.sh [team|club] [firebase-options]
#   Arguments:
#     team - Deploy TeamSync app
#     club - Deploy ClubSync app
#   Options: pass any additional firebase deploy options

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if app type is provided
if [ $# -eq 0 ]; then
  echo "❌ Error: Please specify which app to deploy"
  echo ""
  echo "Usage: ./scripts/deploy-web.sh [team|club] [firebase-options]"
  echo ""
  echo "Examples:"
  echo "  ./scripts/deploy-web.sh team              # Deploy TeamSync"
  echo "  ./scripts/deploy-web.sh club              # Deploy ClubSync"
  echo "  ./scripts/deploy-web.sh team --only hosting  # Deploy TeamSync hosting only"
  exit 1
fi

APP_TYPE=$1
shift  # Remove first argument, keeping any remaining ones

# Validate app type and set configuration
case $APP_TYPE in
  team)
    echo "🏆 Deploying TeamSync (Single-Team Management)..."
    APP_NAME="TeamSync"
    BUILD_SCRIPT="$SCRIPT_DIR/build-team-sync.sh"
    HOSTING_SITE="team-sync-soccer"
    ;;
  club)
    echo "🏟️  Deploying ClubSync (Multi-Team Club Management)..."
    APP_NAME="ClubSync"
    BUILD_SCRIPT="$SCRIPT_DIR/build-club-sync.sh"
    HOSTING_SITE="team-sync-club-soccer"
    ;;
  *)
    echo "❌ Error: Invalid app type '$APP_TYPE'"
    echo "Must be either 'team' or 'club'"
    exit 1
    ;;
esac

echo ""
echo "🔨 Building $APP_NAME web..."
"$BUILD_SCRIPT" web

echo ""
echo "🚀 Deploying $APP_NAME to Firebase hosting site: $HOSTING_SITE..."
cd "$PROJECT_ROOT"

# Ensure we're using the correct Firebase project
firebase use team-sync-soccer

# If no additional arguments provided, default to --only hosting with specific site
if [ $# -eq 0 ]; then
  firebase deploy --only hosting:$HOSTING_SITE
else
  # Add the hosting site to any custom deploy arguments
  firebase deploy --only hosting:$HOSTING_SITE "$@"
fi

echo ""
echo "✅ $APP_NAME deployment complete!"

