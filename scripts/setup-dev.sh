#!/usr/bin/env bash
# Setup dev machine: install pre-commit hook and optionally configure core.hooksPath
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Installing pre-commit hook..."
chmod +x "$ROOT_DIR/scripts/install-githook.sh"
"$ROOT_DIR/scripts/install-githook.sh"

echo "Pre-commit hook installed to .git/hooks/pre-commit"

read -p "Would you like to configure git to use the repository .githooks directory as hooksPath for this repo? (y/N) " -r
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  git config core.hooksPath .githooks
  echo "Configured git core.hooksPath to .githooks"
else
  echo "Skipping core.hooksPath configuration. You can run: git config core.hooksPath .githooks"
fi

echo "Done. Run './scripts/load_firebase_env.sh run -d chrome' to start the app with local env values."

