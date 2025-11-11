Protecting main branch (automation and hooks)

This repo includes scripts to help you enforce a no-direct-merge policy on the `main` branch.

What I added
- `scripts/set-github-branch-protection.sh` — uses the GitHub REST API to set branch protection rules on a repository.
- `scripts/hooks/pre-push` — a client-side git hook that blocks pushes from `main`/`master`.
- `scripts/install-client-hooks.sh` — helper to copy the hooks into `.git/hooks`.

How to use
1) Server-side (recommended): use GitHub branch protection (via the script or via the web UI)

To run the provided script (requires a token with repo permissions):

```bash
GITHUB_TOKEN=ghp_xxx REPO_OWNER=your-org REPO_NAME=your-repo ./scripts/set-github-branch-protection.sh
```

Optional environment variables:
- `BRANCH` (default: `main`)
- `REQUIRED_STATUS_CONTEXTS` (comma-separated list of CI contexts that must pass)
- `REQUIRED_APPROVALS` (default: 1)
- `ENFORCE_ADMINS` (true/false)
- `RESTRICT_PUSH_USERS` (comma-separated users allowed to push)
- `RESTRICT_PUSH_TEAMS` (comma-separated team slugs allowed to push)

2) Client-side (optional): prevent accidental pushes from local clones

From your repository root run:

```bash
./scripts/install-client-hooks.sh
```

This will copy `scripts/hooks/pre-push` to `.git/hooks/pre-push` and make it executable.

Notes and caveats
- Server-side branch protection is the authoritative enforcement mechanism — client hooks are advisory and can be bypassed.
- If you enable restrictions on who can push, remember to allow any CI/service accounts that need to push.
- Admins can bypass protections unless you explicitly enforce them for admins in the UI or via the API.

If you want, I can run the script for this repo now if you provide a GitHub token with the right permissions (or I can show the exact web UI steps).
