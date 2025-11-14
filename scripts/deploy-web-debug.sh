#!/bin/bash

# Deploy Flutter web DEBUG build to Firebase Hosting
# This script builds the web app in debug mode and deploys it
# Usage: ./scripts/deploy-web-debug.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔨 Building Flutter web in DEBUG mode..."
"$SCRIPT_DIR/build-web-debug.sh"

echo ""
echo "🚀 Deploying DEBUG build to Firebase..."
cd "$PROJECT_ROOT"
firebase deploy --only hosting

echo ""
echo "✅ Debug deployment complete!"
echo ""
echo "⚠️  WARNING: This is a DEBUG build with source maps."
echo "   Don't forget to deploy production build when done debugging:"
echo "   ./scripts/deploy-web.sh"

