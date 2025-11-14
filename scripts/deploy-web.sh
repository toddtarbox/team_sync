#!/bin/bash

# Deploy Flutter web to Firebase Hosting
# This script builds the web app and deploys it in one command
# Usage: ./scripts/deploy-web.sh [options]
#   Options: pass any firebase deploy options, e.g., --only hosting

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔨 Building Flutter web..."
"$SCRIPT_DIR/build-web.sh"

echo ""
echo "🚀 Deploying to Firebase..."
cd "$PROJECT_ROOT"

# If no arguments provided, default to --only hosting
if [ $# -eq 0 ]; then
  firebase deploy --only hosting
else
  firebase deploy "$@"
fi

echo ""
echo "✅ Deployment complete!"

