#!/bin/sh
# Generates ios/Runner/GoogleService-Info.plist from a .env file found by walking up from the iOS project.
# This script prefers values from .env; if a value is not present it will try to keep existing plist value or a sensible default.

set -e

# Find .env by walking up from SRCROOT (the ios folder in most setups)
find_env() {
  dir="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
  while [ -n "$dir" ]; do
    if [ -f "$dir/.env" ]; then
      echo "$dir/.env"
      return 0
    fi
    parent=$(dirname "$dir")
    if [ "$parent" = "$dir" ]; then
      break
    fi
    dir="$parent"
  done
  return 1
}

ENV_FILE=$(find_env) || true
if [ -z "$ENV_FILE" ]; then
  echo "[generate_google_service_info] .env not found; skipping generation of GoogleService-Info.plist"
  exit 0
fi

echo "[generate_google_service_info] Using .env at $ENV_FILE"

# Simple .env parser (KEY=VALUE). Lines starting with # or empty lines are ignored.
set -a
while IFS= read -r line || [ -n "$line" ]; do
  # trim
  line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$line" ] && continue
  case "$line" in
    \#*) continue ;; # comment
    *=*)
      key="$(echo "$line" | sed -E 's/=.*$//')"
      value="$(echo "$line" | sed -E 's/^[^=]*=//')"
      # remove surrounding quotes
      value="$(echo "$value" | sed -E 's/^"(.*)"$/\1/; s/^\'(.*)\'$/\1/')"
      export "$key=$value"
      ;;
    *) ;;
  esac
done < "$ENV_FILE"
set +a

PLIST_PATH="$SRCROOT/Runner/GoogleService-Info.plist"

# Helper to read existing plist values using PlistBuddy (if file exists)
read_plist() {
  if [ -f "$PLIST_PATH" ]; then
    /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST_PATH" 2>/dev/null || true
  fi
}

# Prefer env var, else existing plist, else default
get_val() {
  key="$1"; envvar="$2"; default="$3"
  val=""
  # env var present?
  if [ -n "${!envvar}" ]; then
    val="${!envvar}"
  else
    existing=$(read_plist "$key")
    if [ -n "$existing" ]; then
      val="$existing"
    else
      val="$default"
    fi
  fi
  echo "$val"
}

CLIENT_ID=$(get_val "CLIENT_ID" "CLIENT_ID" "")
if [ -z "$CLIENT_ID" ] && [ -n "$IOS_CLIENT_ID" ]; then
  CLIENT_ID="$IOS_CLIENT_ID"
fi
REVERSED_CLIENT_ID=$(get_val "REVERSED_CLIENT_ID" "REVERSED_CLIENT_ID" "")
if [ -z "$REVERSED_CLIENT_ID" ] && [ -n "$CLIENT_ID" ]; then
  REVERSED_CLIENT_ID="com.googleusercontent.apps.$CLIENT_ID"
fi
ANDROID_CLIENT_ID=$(get_val "ANDROID_CLIENT_ID" "ANDROID_CLIENT_ID" "")
API_KEY=$(get_val "API_KEY" "API_KEY" "")
GCM_SENDER_ID=$(get_val "GCM_SENDER_ID" "FIREBASE_PROJECT_NUMBER" "")
PLIST_VERSION=$(get_val "PLIST_VERSION" "PLIST_VERSION" "1")
# Prefer BUNDLE_ID env or Xcode's PRODUCT_BUNDLE_IDENTIFIER
BUNDLE_ID="${BUNDLE_ID:-$PRODUCT_BUNDLE_IDENTIFIER}"
if [ -z "$BUNDLE_ID" ]; then
  BUNDLE_ID=$(get_val "BUNDLE_ID" "BUNDLE_ID" "${PRODUCT_BUNDLE_IDENTIFIER}")
fi
PROJECT_ID=$(get_val "PROJECT_ID" "FIREBASE_PROJECT_ID" "")
STORAGE_BUCKET=$(get_val "STORAGE_BUCKET" "FIREBASE_STORAGE_BUCKET" "")
IS_ADS_ENABLED=$(get_val "IS_ADS_ENABLED" "IS_ADS_ENABLED" "false")
IS_ANALYTICS_ENABLED=$(get_val "IS_ANALYTICS_ENABLED" "IS_ANALYTICS_ENABLED" "false")
IS_APPINVITE_ENABLED=$(get_val "IS_APPINVITE_ENABLED" "IS_APPINVITE_ENABLED" "true")
IS_GCM_ENABLED=$(get_val "IS_GCM_ENABLED" "IS_GCM_ENABLED" "true")
IS_SIGNIN_ENABLED=$(get_val "IS_SIGNIN_ENABLED" "IS_SIGNIN_ENABLED" "true")
GOOGLE_APP_ID=$(get_val "GOOGLE_APP_ID" "FIREBASE_IOS_APP_ID" "")
if [ -z "$GOOGLE_APP_ID" ]; then
  GOOGLE_APP_ID=$(get_val "GOOGLE_APP_ID" "GOOGLE_APP_ID" "")
fi
DATABASE_URL=$(get_val "DATABASE_URL" "FIREBASE_DATABASE_URL" "")

# Ensure directory exists
mkdir -p "$(dirname "$PLIST_PATH")"

# Write the plist
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLIENT_ID</key>
	<string>${CLIENT_ID}</string>
	<key>REVERSED_CLIENT_ID</key>
	<string>${REVERSED_CLIENT_ID}</string>
	<key>ANDROID_CLIENT_ID</key>
	<string>${ANDROID_CLIENT_ID}</string>
	<key>API_KEY</key>
	<string>${API_KEY}</string>
	<key>GCM_SENDER_ID</key>
	<string>${GCM_SENDER_ID}</string>
	<key>PLIST_VERSION</key>
	<string>${PLIST_VERSION}</string>
	<key>BUNDLE_ID</key>
	<string>${BUNDLE_ID}</string>
	<key>PROJECT_ID</key>
	<string>${PROJECT_ID}</string>
	<key>STORAGE_BUCKET</key>
	<string>${STORAGE_BUCKET}</string>
	<key>IS_ADS_ENABLED</key>
	<${IS_ADS_ENABLED:?false}></${IS_ADS_ENABLED:?false}>
	<key>IS_ANALYTICS_ENABLED</key>
	<${IS_ANALYTICS_ENABLED:?false}></${IS_ANALYTICS_ENABLED:?false}>
	<key>IS_APPINVITE_ENABLED</key>
	<${IS_APPINVITE_ENABLED:?true}></${IS_APPINVITE_ENABLED:?true}>
	<key>IS_GCM_ENABLED</key>
	<${IS_GCM_ENABLED:?true}></${IS_GCM_ENABLED:?true}>
	<key>IS_SIGNIN_ENABLED</key>
	<${IS_SIGNIN_ENABLED:?true}></${IS_SIGNIN_ENABLED:?true}>
	<key>GOOGLE_APP_ID</key>
	<string>${GOOGLE_APP_ID}</string>
	<key>DATABASE_URL</key>
	<string>${DATABASE_URL}</string>
</dict>
</plist>
EOF

echo "[generate_google_service_info] Wrote $PLIST_PATH"

exit 0
