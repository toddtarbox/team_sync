#!/bin/bash

# Deploy Flutter web to Firebase Hosting
# This script builds the web app and deploys it in one command
# Usage: ./scripts/deploy-web.sh [firebase-options]
#   Options: pass any firebase deploy options

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🏆 Deploying TeamSync (Team Management)..."
APP_NAME="TeamSync"
BUILD_SCRIPT="$SCRIPT_DIR/build-team-sync.sh"
HOSTING_SITE="team-sync-soccer"

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

