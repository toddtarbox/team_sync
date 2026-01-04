---
description: Migrate player data to include compound keys
---
This workflow is a placeholder. Since this migration involves updating potentially thousands of records in the live database, it's safer to run this as a dedicated Dart script or Cloud Function rather than a simple shell script.

To migrate manually:
1.  Deploy the new security rules.
2.  Deploy the updated app code.
3.  Any player saved from now on will have the key.
4.  To backfill, you would need to iterate over all players and re-save them.

// turbo
echo "Migration requires careful execution. Please run a custom script to backfill 'teamId_seasonId' for all existing players."
