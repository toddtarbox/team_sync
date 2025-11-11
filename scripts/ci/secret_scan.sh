#!/usr/bin/env bash
# Scan committed (tracked) files for common secret patterns and fail if any are found.
# This script is intended for CI (e.g., GitHub Actions) to scan PRs for accidental secrets.
set -euo pipefail

echo "[secret-scan] scanning committed files for secret patterns..."

# Build patterns at runtime to avoid literal strings in source
PAT_AI="A""I""za""[0-9A-Za-z_-]{10,}"
PAT_PK="-----BEGIN PRIVATE KEY-----"
PAT_RSA="-----BEGIN RSA PRIVATE KEY-----"
PAT_AK="AKIA[0-9A-Z]{8,}"
PAT_AWS="aws_secret_access_key"
PAT_XOX="xox[baprs]-"
PAT_CLIENT="client_secret"
PAT_PRIVKEY="PRIVATE_KEY="

# Patterns array
PATTERNS=(
  "$PAT_AI"
  "$PAT_PK"
  "$PAT_RSA"
  "$PAT_AK"
  "$PAT_AWS"
  "$PAT_XOX"
  "$PAT_CLIENT"
  "$PAT_PRIVKEY"
)

# Files/dirs to exclude from scanning (performance and to skip generated/binary files)
# Also exclude local hook and CI scripts (e.g., .githooks/ and scripts/) which may contain
# example patterns or the scanner itself to avoid self-detection.
EXCLUDE_PATTERN='^(\.git/|build/|\.dart_tool/|\.pub/|\.pub-cache/|node_modules/|\.github/|android/gradle/|ios/Pods/|\.vscode/|\.githooks/|scripts/)'

# Get list of tracked files to scan
FILES=$(git ls-files | grep -Ev "$EXCLUDE_PATTERN" || true)
if [ -z "$FILES" ]; then
  echo "[secret-scan] no tracked files to scan"
  exit 0
fi

FOUND=0

for pat in "${PATTERNS[@]}"; do
  # Use grep to find matches in tracked files. We only surface filename:line number.
  # Silence grep exit status when no matches are found.
  MATCHES=$(grep -nE -- "$pat" $FILES 2>/dev/null || true)
  if [ -n "$MATCHES" ]; then
    echo "[secret-scan] pattern '$pat' matched in the following files (filename:line):"
    echo "$MATCHES" | cut -d: -f1,2 | sed -n '1,200p'
    FOUND=1
  fi
done

if [ $FOUND -ne 0 ]; then
  echo
  echo "::error::Potential secrets detected in committed files. Please remove secrets (move to env/CI secrets) and re-run." >&2
  exit 1
fi

echo "[secret-scan] no secrets found"
exit 0
