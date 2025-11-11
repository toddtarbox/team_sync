#!/usr/bin/env bash
# Local helper to run gitleaks (if installed) against the repo.
set -euo pipefail

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is not installed. Install it with:"
  echo "  - brew install gitleaks        # macOS (Homebrew)"
  echo "  - or see https://github.com/gitleaks/gitleaks#installation"
  exit 2
fi

echo "Running gitleaks against repository..."
# run gitleaks detect in repo root
gitleaks detect --source . --verbose || exit $?

echo "gitleaks completed"

