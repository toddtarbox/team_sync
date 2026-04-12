#!/bin/bash

# Run Flutter web in development mode with Firebase secrets from .env file
# Usage: ./scripts/run-team-web.sh [soccer|basketball]

set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Determine target (default to soccer)
SPORT=${1:-"soccer"}

# Determine entry point
if [ "$SPORT" == "basketball" ]; then
  ENTRY_POINT="lib/main_basketball.dart"
else
  ENTRY_POINT="lib/main_soccer.dart"
fi

# Path to .env file
ENV_FILE="$PROJECT_ROOT/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Please create a .env file with your Firebase configuration."
  exit 1
fi

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Verify required variables for web are set
REQUIRED_VARS=(
  "WEB_API_KEY"
  "WEB_APP_ID"
  "MESSAGING_SENDER_ID"
  "FIREBASE_PROJECT_ID"
  "FIREBASE_DATABASE_URL"
  "FIREBASE_STORAGE_BUCKET"
  "WEB_AUTH_DOMAIN"
  "WEB_MEASUREMENT_ID"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "Error: Required environment variable $var is not set in .env"
    exit 1
  fi
done

echo -e "${BLUE}Running TeamSync ($SPORT) web with Firebase configuration from .env...${NC}"
echo "Project: $FIREBASE_PROJECT_ID"
echo "Entry Point: $ENTRY_POINT"
echo ""

# Run TeamSync web with all dart-defines
cd "$PROJECT_ROOT"
flutter run -d chrome --web-port 5000 \
  -t "$ENTRY_POINT" \
  --dart-define=WEB_API_KEY="$WEB_API_KEY" \
  --dart-define=WEB_APP_ID="$WEB_APP_ID" \
  --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=WEB_AUTH_DOMAIN="$WEB_AUTH_DOMAIN" \
  --dart-define=WEB_MEASUREMENT_ID="$WEB_MEASUREMENT_ID"

