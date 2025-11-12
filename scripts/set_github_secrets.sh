#!/usr/bin/env bash
# Upload required GitHub repository secrets from a local .env file using gh CLI.
# Usage: ./scripts/set_github_secrets.sh [owner/repo]
# If owner/repo is omitted, the script will attempt to read it from the git remote.

set -euo pipefail
IFS=$'\n\t'

REPO_ARG=${1:-}
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  REPO_ARG=${2:-}
fi

# Required keys list (must match keys used in .github/workflows/ci.yml)
REQUIRED_KEYS=(
  FIREBASE_PROJECT_NUMBER
  FIREBASE_DATABASE_URL
  FIREBASE_PROJECT_ID
  FIREBASE_STORAGE_BUCKET
  FIREBASE_MOBILE_APP_ID
  ANDROID_PACKAGE_NAME
  API_KEY
  OAUTH_CLIENT_IDS
  IOS_APPINVITE_CLIENT_ID
  IOS_BUNDLE_ID
  IOS_CLIENT_ID
  IOS_REVERSED_CLIENT_ID
  IOS_ANDROID_CLIENT_ID
  IOS_API_KEY
  IOS_GCM_SENDER_ID
  IOS_GOOGLE_APP_ID
  MESSAGING_SENDER_ID
)

# Optional keys (web-related can be optional depending on your use)
OPTIONAL_KEYS=(
  WEB_API_KEY
  WEB_APP_ID
  WEB_AUTH_DOMAIN
  WEB_MEASUREMENT_ID
)

# Combine required + optional for upload loop
ALL_KEYS=(${REQUIRED_KEYS[@]} ${OPTIONAL_KEYS[@]})

# Determine repo (owner/repo)
if [[ -n "$REPO_ARG" ]]; then
  OWNER_REPO="$REPO_ARG"
else
  remote_url=$(git config --get remote.origin.url || true)
  if [[ -z "$remote_url" ]]; then
    echo "Could not detect git remote origin. Please pass owner/repo as the first argument."
    exit 1
  fi

  # support git@github.com:owner/repo.git and https://github.com/owner/repo.git
  if [[ "$remote_url" =~ github.com[:/]+([^/]+)/([^/.]+)(\.git)?$ ]]; then
    OWNER_REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    echo "Unable to parse remote origin URL: $remote_url"
    echo "Please pass owner/repo as the first argument."
    exit 1
  fi
fi

# Check for gh CLI
if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required but not found. Install it: https://cli.github.com/"
  exit 1
fi

# Check .env exists
if [[ ! -f .env ]]; then
  echo ".env file not found in the repo root. Create one or set environment variables for the keys."
  exit 1
fi

# Helper: get value: prefer existing process env var, then parse .env file
get_value() {
  key="$1"
  # Use shell parameter expansion to read environment variable if present
  if [ "${!key:-}" != "" ]; then
    echo "${!key}"
    return
  fi
  # Fallback: find the key in .env (strip comments/leading whitespace)
  # grep pattern: ^\s*KEY\s*=
  line=$(grep -m1 -E "^\s*${key}\s*=" .env || true)
  if [ -n "$line" ]; then
    # Extract value after first '=' (preserve '=' in value if present)
    val="${line#*=}"
    # Remove surrounding quotes if present
    # Handle both single and double quotes
    if [[ ${val:0:1} == '"' && ${val: -1} == '"' ]] || [[ ${val:0:1} == "'" && ${val: -1} == "'" ]]; then
      val="${val:1:-1}"
    fi
    # Trim whitespace
    val=$(echo "$val" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    echo "$val"
    return
  fi
  echo ""
}

# First validate required keys exist
echo "Validating required secrets for repository: ${OWNER_REPO}"
missing=false
for key in "${REQUIRED_KEYS[@]}"; do
  v=$(get_value "$key")
  if [[ -z "$v" ]]; then
    echo "ERROR: Required secret $key is missing"
    missing=true
  fi
done
if [[ "$missing" == true ]]; then
  echo "One or more required secrets are missing. Aborting."
  exit 1
fi

echo "All required secrets present (optional keys may be absent). Proceeding to set secrets..."

# Upload each secret (required + optional). If optional key is missing, skip with notice.
for key in "${ALL_KEYS[@]}"; do
  val=$(get_value "$key")
  if [[ -z "$val" ]]; then
    if [[ " ${OPTIONAL_KEYS[*]} " == *" $key "* ]]; then
      echo "Skipping optional secret (missing): $key"
      continue
    else
      # Should not happen because we validated required keys earlier
      echo "ERROR: Required secret $key missing unexpectedly"
      exit 1
    fi
  fi
  if [[ "$DRY_RUN" == true ]]; then
    echo "DRY RUN: gh secret set $key --repo $OWNER_REPO (value length=${#val})"
  else
    echo "Setting secret: $key"
    gh secret set "$key" --repo "$OWNER_REPO" --body "$val"
  fi
done

echo "All secrets processed for $OWNER_REPO"

# End of script
