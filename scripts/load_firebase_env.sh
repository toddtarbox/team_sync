#!/usr/bin/env bash
# Usage: ./scripts/load_firebase_env.sh flutter_run|flutter_build [additional flutter args]
# This script loads key=value pairs from .env (ignored) and passes them to flutter
# via --dart-define. It only supports simple VAR=VALUE lines (no export, no spaces around =).

set -eo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "No .env file found at $ENV_FILE"
  exit 1
fi

# Read variables we care about and build dart-define flags
DART_DEFINES=()
read_env() {
  local key="$1"
  local val
  val=$(grep -E "^${key}=" "$ENV_FILE" | head -n1 | cut -d'=' -f2- || true)
  if [ -n "$val" ]; then
    DART_DEFINES+=("--dart-define=${key}=${val}")
  fi
}

# List of allowed env variable names (documented in .env.example and docs)
VAR_NAMES=(
  FIREBASE_ANDROID_API_KEY
  FIREBASE_ANDROID_APP_ID
  FIREBASE_IOS_API_KEY
  FIREBASE_IOS_APP_ID
  FIREBASE_MESSAGING_SENDER_ID
  FIREBASE_PROJECT_ID
  FIREBASE_DATABASE_URL
  FIREBASE_STORAGE_BUCKET
  FIREBASE_ANDROID_CLIENT_ID
  FIREBASE_IOS_CLIENT_ID
  FIREBASE_IOS_BUNDLE_ID
  FIREBASE_WEB_API_KEY
  FIREBASE_WEB_APP_ID
  FIREBASE_AUTH_DOMAIN
  FIREBASE_MEASUREMENT_ID
)

for v in "${VAR_NAMES[@]}"; do
  read_env "$v"
done

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <flutter_command> [args...]"
  echo "Example: $0 run -d chrome"
  exit 2
fi

FLUTTER_CMD=("flutter" "$@" "${DART_DEFINES[@]}")

# Print and execute
echo "Running: ${FLUTTER_CMD[*]}"
exec "${FLUTTER_CMD[@]}"

