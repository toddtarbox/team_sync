#!/bin/bash

# Run ClubSync web in development mode with Firebase secrets from .env file
# Usage: ./scripts/run-club-web.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# Verify required variables for ClubSync web are set
REQUIRED_VARS=(
  "WEB_API_KEY"
  "CLUBSYNC_WEB_APP_ID"
  "MESSAGING_SENDER_ID"
  "FIREBASE_PROJECT_ID"
  "FIREBASE_DATABASE_URL"
  "FIREBASE_STORAGE_BUCKET"
  "CLUBSYNC_WEB_AUTH_DOMAIN"
  "CLUBSYNC_WEB_MEASUREMENT_ID"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "Error: Required environment variable $var is not set in .env"
    exit 1
  fi
done

echo "Running ClubSync web with Firebase configuration from .env..."
echo "Project: $FIREBASE_PROJECT_ID"
echo ""

# Run ClubSync web with all dart-defines
cd "$PROJECT_ROOT"
flutter run -d chrome --web-port 5001 \
  -t lib/main_club_sync.dart \
  --dart-define=WEB_API_KEY="$WEB_API_KEY" \
  --dart-define=CLUBSYNC_WEB_APP_ID="$CLUBSYNC_WEB_APP_ID" \
  --dart-define=MESSAGING_SENDER_ID="$MESSAGING_SENDER_ID" \
  --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
  --dart-define=FIREBASE_DATABASE_URL="$FIREBASE_DATABASE_URL" \
  --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
  --dart-define=CLUBSYNC_WEB_AUTH_DOMAIN="$CLUBSYNC_WEB_AUTH_DOMAIN" \
  --dart-define=CLUBSYNC_WEB_MEASUREMENT_ID="$CLUBSYNC_WEB_MEASUREMENT_ID"

