# team_sync

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Secrets & local dev setup

This project keeps API keys and other secrets out of source control. Follow these steps for a secure local setup:

1) Create a local `.env` from the example and fill in your Firebase values (this file is gitignored):

```bash
cp .env.example .env
# edit .env and fill values
```

2) Install the local Git pre-commit hook (prevents committing secrets locally):

```bash
# Installs the hook into .git/hooks
chmod +x scripts/install-githook.sh
./scripts/install-githook.sh

# OR (optional) configure Git to use the repo hooks directory for all hooks
# This avoids copying hooks into .git/hooks, but it's per-repo config.
# git config core.hooksPath .githooks
```

3) Use the helper to run Flutter with `.env` values injected via `--dart-define`:

```bash
# Example: run on chrome
./scripts/load_firebase_env.sh run -d chrome

# Example: build android
./scripts/load_firebase_env.sh build apk
```

4) CI protection: the repository has a GitHub Actions job `.github/workflows/secret_scan.yml`
that scans committed files in pull requests for common secret patterns and will fail the PR if any are found.

5) Additional robust scanning with gitleaks:

- CI: The PR scanner runs `gitleaks` via the `zricethezav/gitleaks-action` (see `.github/workflows/secret_scan.yml`).
- Local: You can run `gitleaks` locally if you have it installed. There's a helper script:

```bash
# Make sure gitleaks is installed, e.g. brew install gitleaks
./scripts/ci/run_gitleaks.sh
```

6) gitleaks allowlist:

This repository includes a `.gitleaksignore` file to configure paths and files that gitleaks should ignore (e.g., `.env` and generated build dirs). Modify it if you need to allow additional files.

Security notes:
- Never commit `.env` or any files containing secrets. If secrets were previously pushed, rotate them.
- The local pre-commit hook is a helpful guard but developers can bypass hooks; server-side scanning (the CI job) enforces checks on PRs.

See `CONTRIBUTING.md` for step-by-step setup instructions.

If you want, run `./scripts/setup-dev.sh` to automate hook installation and optional repo hook-path configuration.
