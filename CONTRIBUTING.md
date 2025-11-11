# Contributing

Welcome — thanks for contributing! This file explains the minimal setup required to work on this repository safely with respect to secrets.

## Quick setup (recommended)

1. Copy the example env and fill values (local only):

    ```bash
    cp .env.example .env
    # edit .env and fill values
    ```

2. Install the project's Git pre-commit hook (prevents accidental commits of secrets):

    ```bash
    chmod +x scripts/setup-dev.sh
    ./scripts/setup-dev.sh
    ```

3. Optionally run local secret scans:

    ```bash
    # grep-based scan
    ./scripts/ci/secret_scan.sh

    # gitleaks (if installed)
    ./scripts/ci/run_gitleaks.sh
    ```

4. Use the helper to run Flutter with local env injected:

    ```bash
    # Example: run on chrome
    ./scripts/load_firebase_env.sh run -d chrome
    ```

## CI protections

- Pull requests are scanned by a CI job (`.github/workflows/secret_scan.yml`) which runs a conservative grep-based scan and `gitleaks`. The job will fail if suspected secrets are detected.

## Branch protection recommendation

To protect the main branch, configure branch protection rules in GitHub:

- Require status checks to pass before merging.
- Add the secret-scan job name `Secret scan` (and other relevant checks) as required checks.
- Require pull request reviews before merging.

## If secrets were committed previously

If you discover secrets in repository history, rotate the keys immediately in the external provider (e.g., Firebase console) and remove the secrets from the Git history. Contact a repo admin if you need help.
