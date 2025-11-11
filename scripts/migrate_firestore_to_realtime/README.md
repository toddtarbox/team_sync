# Firestore → Realtime Database Migration Tool

This is a small admin migration script that copies collections from a Firestore document into the Firebase Realtime Database. It uses the Firebase Admin SDK and preserves Firestore document IDs as keys in the Realtime Database.

Prerequisites
- Node 18+ installed
- A Firebase service account JSON key for your project (download from Firebase Console / IAM)

Install

```bash
cd scripts/migrate_firestore_to_realtime
npm install
```

Quick usage

Dry-run (no writes):

```bash
node migrate.js --serviceAccount /path/to/serviceAccountKey.json \
  --firestoreDocPath "databases/myDb" \
  --rtBasePath "subscriptionIds/<uid>/databases/myDb" \
  --dry-run
```

Perform migration (writes to RTDB):

```bash
node migrate.js --serviceAccount /path/to/serviceAccountKey.json \
  --firestoreDocPath "databases/myDb" \
  --rtBasePath "subscriptionIds/<uid>/databases/myDb"
```

Options
- `--serviceAccount <key.json>` (required) — path to Firebase service account key file
- `--firestoreDocPath <path>` (required) — Firestore document path that contains the collections to migrate (e.g. `databases/myDb` or `users/<uid>/databases/myDb`)
- `--rtBasePath <path>` (required) — Realtime DB base path to write to (e.g. `subscriptionIds/<uid>/databases/myDb`)
- `--dry-run` — don't write to Realtime DB, only show what would be written
- `--tables t1,t2` — optional comma-separated list of collections to migrate (defaults to Teams,Seasons,Players,Games,Events)
- `--yes` — skip the interactive confirmation prompt and proceed immediately
- `--no-backup` — skip creating backups of existing Realtime Database data before overwriting

Backups
- By default, the script will create backups of any existing Realtime Database data it will overwrite under the path:

  `<rtBasePath>/__backups__/<timestamp>/<table>`

  where `<timestamp>` is an ISO-like timestamp with colons and dots replaced to be safe in paths.

Notes and limitations
- This script is intended for one-time migrations and requires admin credentials.
- It preserves Firestore document IDs when writing to RTDB.
- Timestamps are converted to ISO-8601 strings; GeoPoints are converted to `{lat,lng}`.
- For very large datasets a more robust streaming approach is recommended.

If you'd like, I can:
- Add additional safety checks (confirmation prompts, backups, incremental sync).
- Implement a version that runs in Google Cloud Functions / Cloud Run with IAM.
- Add logging and retry/backoff for large migrations.
