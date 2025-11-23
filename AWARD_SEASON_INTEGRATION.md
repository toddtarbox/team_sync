# Award Season Integration & Player Card Enhancement

## Overview
Updated the awards system to use seasonId instead of dates, and integrated awards display into the player card generator's back side. Season names are loaded on-demand for display purposes.

## Changes Made

### 1. PlayerAward Model (`lib/models/player_award.dart`)

**Replaced:**
- `DateTime date` field

**Added:**
- `int seasonId` field (required)
- `getSeasonName()` method - loads season name on-demand for display

**Removed:**
- No season object stored in the model

**Updated Methods:**
- `fromMap()` - now reads `seasonId` instead of `date`
- `toMap()` - now writes `seasonId` instead of `date`
- `listFromPlayerId()` - sorts by seasonId directly (no need to load full season objects)
- `getSeasonName()` - helper method to fetch season name when needed for display

**Benefits:**
- More meaningful context (season ID vs arbitrary date)
- Better data organization
- Cleaner model without embedded objects
- Season names loaded only when displaying (efficient)
- Consistent with team structure

### 2. Player Profile Editor (`lib/widgets/player_profile_editor.dart`)

**Replaced Date Picker with Season Selector:**
- Loads all seasons for the player's team using `Season.fromTeamId()`
- Shows dropdown with season names
- When editing, finds matching season by ID
- Defaults to most recent season
- Validates that a season is selected before saving

**Updated Award Dialog:**
```dart
// Old: Date picker
ListTile with DatePicker

// New: Season dropdown with ID lookup
DropdownButtonFormField<Season>
// When editing: seasons.firstWhere((s) => s.id == award.seasonId)
```

**Updated Award Display:**
- Uses FutureBuilder to load season name on-demand via `award.getSeasonName()`
- Awards sorted by seasonId (most recent first)
- Fallback display: "Season {seasonId}" if name can't be loaded

### 3. Player Profile Page (`lib/widgets/player_profile_page.dart`)

**Updated Awards Section:**
- Uses FutureBuilder to load season name for each award via `award.getSeasonName()`
- Removed date display
- Better visual hierarchy with season names
- Fallback display if season not found

### 4. Player Card Generator (`lib/widgets/player_card_generator.dart`)

**Added Awards to Card Back:**
- Imported `PlayerAward` model
- Added awards loading in `_PlayerCardBackWidgetState`
- Displays up to 3 awards on card back
- Uses FutureBuilder to load season names asynchronously
- Shows trophy icon with award title and season
- Integrated with existing stats display

**Card Back Layout:**
```
┌─────────────────────────┐
│     CAREER STATS        │
├─────────────────────────┤
│  #5  Player Name        │
│      Team Name          │
├─────────────────────────┤
│  ⚽ GOALS: 12           │
│  👥 ASSISTS: 8          │
│  ✋ SAVES: 45           │
├─────────────────────────┤
│       AWARDS            │
│  🏆 MVP                 │
│     2024 Season         │
│  🏆 ALL-STAR            │
│     2023 Season         │
│  🏆 TOP SCORER          │
│     2024 Season         │
└─────────────────────────┘
```

**Features:**
- Shows stats first (if any)
- Divider between stats and awards
- Max 3 awards displayed (most recent)
- Trophy icon for visual appeal
- Award title and season name
- Graceful handling when no stats/awards

## Database Schema Update

### PlayerAwards Table
```json
{
  "id": "number",
  "playerId": "number",
  "seasonId": "number",  // NEW: replaces date
  "title": "string",
  "description": "string (optional)",
  "imageUrl": "string (URL, optional)"
}
```

## Migration Notes

⚠️ **Breaking Change:** Existing awards with `date` field will need migration.

**Migration Strategy:**
1. For existing awards, map the date to the appropriate season
2. Or clear existing awards and have users re-add them with seasons
3. Add migration script if needed

## UI/UX Improvements

### Award Creation Flow:
1. Click "Add Award"
2. Enter award title (e.g., "MVP", "All-Star")
3. **Select season from dropdown** (instead of picking date)
4. Optionally add description
5. Optionally upload image
6. Save

### Display:
- **Profile Editor:** Shows season name below award title
- **Profile Page:** Shows season name in subtitle
- **Player Card:** Shows season name below award title with trophy icon

## Benefits

### For Users:
✅ More intuitive - seasons are more meaningful than specific dates
✅ Better organization - awards grouped by season
✅ Consistent with team structure
✅ Awards visible on shareable player cards

### For System:
✅ Better data integrity - seasons are existing entities
✅ Easier querying and filtering
✅ Automatic sorting by recency
✅ Foreign key relationship

## Testing Checklist

- [x] Award creation with season selection
- [x] Award editing preserves season
- [x] Awards display in profile editor
- [x] Awards display in profile page
- [x] Awards display on player card back
- [x] Season names load correctly
- [x] Multiple awards show properly
- [x] No awards shows appropriate message
- [x] Card flips to show back with awards
- [x] No compilation errors

## Examples

### Creating an Award:
```
Title: MVP
Season: 2024 Fall Season
Description: Most Valuable Player of the season
```

### Player Card Back with Awards:
```
Player has:
- 15 goals
- 10 assists
- MVP 2024
- All-Star 2023
- Top Scorer 2024

Card shows all stats and top 3 awards
```

## Future Enhancements

Possible improvements:
1. Award filtering by season
2. Season-specific award statistics
3. Award badges/icons on profile
4. Award comparison across seasons
5. Team-wide award leaderboards
6. Award export/sharing
7. Custom award icons

## Related Features

This change works with:
- ✅ Player self-editing (players can add awards with seasons)
- ✅ PIN authentication (secure award management)
- ✅ Image uploads (award images)
- ✅ Player cards (awards visible on cards)
- ✅ Profile display (awards on profile page)

---

**Status**: ✅ Complete
**Date**: November 23, 2025
**Breaking Change**: Yes (date → seasonId)
**Migration Required**: Yes (for existing awards)

