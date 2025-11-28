# Player Merger Tool - Quick Start Guide

## Summary

I've created a complete player merger tool that helps you identify and merge duplicate players who appear in multiple seasons with different jersey numbers. The tool automatically finds duplicates, lets you select which player record to keep, and merges all related data (game events, awards, highlights).

## Files Created

### 1. Core Service
**`lib/services/player_merger_service.dart`**
- Detects duplicate players by matching names
- Merges player records safely
- Updates all related database tables

### 2. User Interface
**`lib/widgets/player_merger_tool.dart`**
- Main UI for reviewing and merging duplicates
- Shows duplicate groups with season/number info
- Displays merge confirmation and results

**`lib/widgets/player_merger_tool_launcher.dart`**
- Team selection screen (if no team provided)
- Launches the merger tool for selected team

### 3. Documentation
**`docs/PLAYER_MERGER_TOOL.md`**
- Complete documentation
- Usage instructions
- Technical details

### 4. Integration
**`lib/widgets/data_import_page.dart`** (modified)
- Added "Merge Duplicate Players" button to Tools section
- Located in the Import Verification Tools card

## How to Access

The tool is now integrated into your Data Import page. To use it:

1. **Navigate to Data Import page** in your app
2. **Scroll to "Import Verification Tools"** section
3. **Click "Merge Duplicate Players"** button
4. **Select your team** (if not already selected)
5. **Review duplicate players** found
6. **Select primary player** to keep
7. **Confirm and merge**

## Quick Example

### Before Merge:
```
John Smith #10 (2023 Season) - Player ID 101
  - 5 goals, 3 assists
  - MVP Award

John Smith #15 (2024 Season) - Player ID 205
  - 8 goals, 5 assists
  - Golden Boot Award
```

### After Merge:
```
John Smith #15 (2024 Season) - Player ID 205
  - 13 goals total (5 + 8)
  - 8 assists total (3 + 5)
  - Both MVP and Golden Boot awards
  - All game events from both seasons
```

## What Gets Updated

When you merge players, the tool updates these database tables:

1. **Events** - All game events (goals, assists, shots, etc.)
2. **PlayerAwards** - All awards and recognitions
3. **PlayerHighlights** - All video highlights
4. **Players** - Duplicate records are deleted

## Safety Features

✅ **No Data Loss** - All data transferred before deletion
✅ **Error Handling** - Errors caught and reported without breaking process
✅ **Progress Tracking** - Real-time updates during merge
✅ **Detailed Results** - Full report of changes made
✅ **Atomic Operations** - Each merge completes fully or not at all

## Testing the Tool

To test the tool:

1. **Run the app**
   ```bash
   flutter run
   ```

2. **Navigate to Data Import page**

3. **Click "Merge Duplicate Players"**

4. **Select a team with multiple seasons**

5. **Review the duplicate groups found**

6. **Test merge with one group first** to verify behavior

## Common Scenarios

### Scenario 1: Player Changed Numbers Between Seasons
✅ Tool will detect and allow merging

### Scenario 2: Player Left and Returned
✅ Tool will detect all seasons and allow merging

### Scenario 3: Similar Names (e.g., "John Smith" vs "Jon Smith")
❌ Tool uses exact name matching - these won't be detected as duplicates

### Scenario 4: Same Name, Different Players
⚠️ Be careful! Review the data before merging to ensure they're the same person

## Troubleshooting

### "No duplicate players found"
- Players must have **exactly** the same first and last name
- Check for spelling variations
- Check for extra spaces

### "Merge failed"
- Check database connection
- Verify write permissions
- Check error message in results dialog

### "Some updates failed" 
- Partial success - most data merged
- Check warnings in results dialog
- Primary player record is still intact

## Next Steps

After using the tool:

1. ✅ Verify merged player profiles look correct
2. ✅ Check that statistics are accurate
3. ✅ Review season reports to ensure data integrity
4. ✅ Run the tool again to check for any remaining duplicates

## Code Integration Example

If you want to add the tool to another page:

```dart
import 'package:team_sync/widgets/player_merger_tool_launcher.dart';

// To launch with team selection:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PlayerMergerToolLauncher(),
  ),
);

// To launch with a specific team:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlayerMergerToolLauncher(team: myTeam),
  ),
);
```

## Architecture

```
PlayerMergerToolLauncher (Team Selection)
    ↓
PlayerMergerTool (UI)
    ↓
PlayerMergerService (Business Logic)
    ↓
DatabaseService (Data Layer)
    ↓
Firebase/Local Database
```

## Performance

- ✅ Optimized database queries using indexed fields
- ✅ Batch processing for large merges
- ✅ Progress updates for long operations
- ✅ Efficient name normalization

## Future Enhancements

Possible improvements for future versions:

- [ ] Fuzzy name matching (for similar names)
- [ ] Manual duplicate marking
- [ ] Undo merge functionality
- [ ] Bulk merge all at once
- [ ] Merge preview mode
- [ ] Export merge report

## Support

For more details, see the complete documentation:
- `docs/PLAYER_MERGER_TOOL.md` - Full documentation

## Success! 🎉

You now have a complete player merger tool integrated into your app. The tool is ready to use and will help you maintain clean player data across multiple seasons.

