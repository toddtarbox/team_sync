chore: add secret scanning, pre-commit hook, setup scripts, docs

Summary

Adds CI and local protections to prevent accidental secret leakage.

Changes

- Add a conservative grep-based secret scanner for PRs (`scripts/ci/secret_scan.sh`) that scans tracked files in `.github/workflows/secret_scan.yml`.
- Add a local pre-commit hook to detect secrets in staged changes (`.githooks/pre-commit`) and installer `scripts/install-githook.sh`.
- Add developer setup script `scripts/setup-dev.sh` to automate hook installation and optional hooksPath configuration.
- Add helper scripts:
  - `scripts/load_firebase_env.sh` — inject `.env` values into flutter via `--dart-define`.
  - `scripts/ci/secret_scan.sh` — grep-based scanner for CI/local.
- Add docs:
  - `CONTRIBUTING.md` — onboarding and branch protection suggestions.
  - Updates to `README.md` with secrets & setup instructions.
- Add sample branch protection JSON at `.github/branch_protection.json` (requires admin to apply).

Testing done

- Ran local secret scanner (no matches on tracked files).
- Installed and tested pre-commit hook locally; adjusted to detect staged diffs.
- Created branch `chore/add-secret-scans-and-hooks` and pushed to origin.

Checklist for reviewers

- Ensure pre-commit hook logic/patterns are acceptable.
- Confirm CI job `Secret scan` is present and configured.
- Verify docs are clear for dev onboarding.

Notes

This PR moves previously committed Firebase keys to a local `.env` and provides scripts and CI protections to avoid re-committing them. If keys were already exposed publicly, rotate them in the Firebase console immediately.

