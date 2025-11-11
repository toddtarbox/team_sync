#!/usr/bin/env bash
# Installs the local pre-commit hook from .githooks/pre-commit into .git/hooks
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK_SRC="$ROOT_DIR/.githooks/pre-commit"
HOOK_DST="$ROOT_DIR/.git/hooks/pre-commit"

if [ ! -f "$HOOK_SRC" ]; then
  echo "Hook source not found: $HOOK_SRC"
  exit 2
fi

mkdir -p "$(dirname "$HOOK_DST")"
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"

echo "Installed pre-commit hook to $HOOK_DST"

