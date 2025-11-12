#!/usr/bin/env bash
# install-client-hooks.sh
# Copies client git hooks from scripts/hooks/ into .git/hooks/ for the current repo.
# Usage: ./install-client-hooks.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/scripts/hooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

if [ ! -d "$GIT_HOOKS_DIR" ]; then
  echo ".git/hooks not found — are you in the repo root?" >&2
  exit 1
fi

if [ ! -d "$HOOKS_DIR" ]; then
  echo "No hooks directory found at $HOOKS_DIR" >&2
  exit 1
fi

for f in "$HOOKS_DIR"/*; do
  if [ -f "$f" ]; then
    fname=$(basename "$f")
    dest="$GIT_HOOKS_DIR/$fname"
    cp "$f" "$dest"
    chmod +x "$dest"
    echo "Installed hook: $fname"
  fi
done

echo "All hooks installed."

