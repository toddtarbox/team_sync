# Quick Start Guide - Data Import

## Getting Started in 5 Minutes

### Step 1: Navigate to Import Page ✅

The import page is available at `/import` in your app.

**Router Configuration (Already Added):**
```dart
import 'package:team_sync/widgets/data_import_page.dart';

GoRoute(
  path: '/import',
  name: 'import',
  builder: (context, state) => const DataImportPage(),
)
```

Navigate to the import page:
- Web: `http://localhost:port/import`
- Or programmatically: `context.go('/import')`

### Step 2: Download a Template

1. Navigate to the import page
2. Select entity type (e.g., "Player")
3. Click "Download Template"
4. Open the CSV in Excel or Google Sheets

### Step 3: Add Your Data

Fill in the template:

**players_template.csv:**
```csv
firstName,lastName,number,teamId,seasonId
John,Smith,10,1,1
Jane,Doe,7,1,1
Mike,Johnson,23,1,1
```

### Step 4: Upload and Import

1. Click "Select CSV File"
2. Choose your filled template
3. Review the preview
4. Click "Validate Only" to check for errors
5. Fix any errors shown
6. Click "Start Import"
7. Watch progress bar
8. Review results

### Step 5: Handle Errors (if any)

If errors occur:
1. Check the error summary
2. Click "Download Error Report"
3. Open the error CSV
4. Fix issues in "Suggested Fixes" column
5. Re-upload just the error rows

## Example: Import Game Stats

For game statistics files like `Game_2011_vs_Des_Moines_East.txt`:

1. Select "GameEvent" entity type
2. Provide gameId, teamId, seasonId context
3. Upload tab-delimited stats file
4. System automatically:
   - Parses player names and numbers
   - Creates goal events
   - Creates assist events
   - Creates penalty kick events
   - Creates card events
5. Matches players to existing roster
6. Imports all events

## Entity Import Order

Always import in this order to satisfy dependencies:

1. **Teams** (no dependencies)
2. **Seasons** (requires teamId)
3. **Players** (requires teamId, seasonId)
4. **Games** (requires seasonId, homeTeamId, awayTeamId)
5. **GameEvents** (requires gameId, teamId, seasonId, playerId)

## Common Scenarios

### Import a Full Season

1. Import Season: "2024 Fall"
2. Import Players roster
3. Import Games schedule
4. Import GameEvents from each game

### Bulk Update Player Photos

1. Export existing players
2. Add profileImage URLs
3. Re-import (will update existing)

### Import Historical Data

1. Prepare CSV with old game data
2. Set `isFromImport: true` automatically applied
3. Easy to identify imported vs live-tracked data

## Tips

- **Test with 5 rows first** before importing 500
- **Use Validate Only** to check format without importing
- **Check IDs** - teamId/seasonId must exist before importing
- **Date format**: Use `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`
- **Names**: Capitalization auto-fixes (e.g., "McBRIDE" → "McBride")

## Need Help?

See full documentation: [DATA_IMPORT.md](DATA_IMPORT.md)

