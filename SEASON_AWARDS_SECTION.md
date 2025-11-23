# Season Awards Section Implementation

## Overview
Added an awards section to the season page that displays both team awards and player awards for that season. Player awards are clickable and link to the player's profile page.

## Changes Made

### 1. New Model: TeamAward (`lib/models/team_award.dart`)

Created a new model for team-level awards (e.g., Tournament Winner, Championship):

**Fields:**
- `id` - Unique identifier
- `teamId` - Foreign key to team
- `seasonId` - Foreign key to season
- `title` - Award name (e.g., "Tournament Champions")
- `description` - Optional details
- `imageUrl` - Optional trophy/certificate image

**Methods:**
- `listFromSeasonId()` - Get all team awards for a season
- `getSeasonName()` - Helper for display
- `save()` / `delete()` - CRUD operations

### 2. Season Page Updates (`lib/widgets/season_page.dart`)

**Added Imports:**
- `Player` model
- `PlayerAward` model
- `TeamAward` model

**New UI Section:**
Inserted awards section between SeasonRecord and game list:
```
SeasonRecord (Win/Loss/Tie)
    ↓
Awards Section (if any exist)
    ↓
Game List
```

**New Methods:**
1. `_buildAwardsSection()` - Main awards display widget
2. `_loadPlayerAwards()` - Loads player awards with player data
3. `_loadTeamAwards()` - Loads team awards
4. `_buildTeamAwardCard()` - Display team award
5. `_buildPlayerAwardCard()` - Display player award (clickable)

## UI Design

### Awards Section Card

```
┌──────────────────────────────────────┐
│ 🏆 AWARDS                      ▼    │
│    5 awards                          │
├──────────────────────────────────────┤
│ 🏆 Team Awards                       │
│                                      │
│ ┌──────────────────────────────────┐│
│ │ 🏆  Tournament Champions          ││
│ │     2nd Place Regional Finals     ││
│ └──────────────────────────────────┘│
│                                      │
│ 👤 Player Awards                     │
│                                      │
│ ┌──────────────────────────────────┐│
│ │ JD  MVP                        →  ││
│ │     John Doe                      ││
│ └──────────────────────────────────┘│
│ ┌──────────────────────────────────┐│
│ │ JS  Top Scorer                 →  ││
│ │     Jane Smith                    ││
│ └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

### Features

**Team Awards:**
- 🏆 Trophy icon (amber color)
- Award title in bold
- Optional description
- Optional image (displayed as avatar)

**Player Awards:**
- Player avatar or initial
- Award title in bold
- Player name as subtitle
- Arrow icon (→) indicating clickable
- **Taps link to player profile page**

**Smart Display:**
- Only shows if awards exist
- Expandable/collapsible
- Shows total count in subtitle
- Team awards listed first
- Player awards listed second (sorted by player name)
- Divider between sections

## Database Schema

### TeamAwards Table (New)
```json
{
  "id": "number",
  "teamId": "number",
  "seasonId": "number",
  "title": "string",
  "description": "string (optional)",
  "imageUrl": "string (URL, optional)"
}
```

### PlayerAwards Table (Existing)
```json
{
  "id": "number",
  "playerId": "number",
  "seasonId": "number",
  "title": "string",
  "description": "string (optional)",
  "imageUrl": "string (URL, optional)"
}
```

## Navigation

**Player Award Tap:**
```dart
NavigationHelper.navigateTo(
  context,
  '/team/$databaseId/season/${seasonId}/player/${playerId}',
);
```

Clicking a player award navigates to their full profile page where users can see:
- Full stats
- All awards across all seasons
- Video highlights
- Action photos
- More details

## Use Cases

### Team Awards Examples:
- Tournament Champions
- League Winners
- Division Champions
- Playoff Finalists
- Best Record
- Fair Play Award

### Player Awards Examples:
- MVP (Most Valuable Player)
- Golden Boot / Top Scorer
- Golden Glove / Best Goalkeeper
- Rookie of the Year
- Most Improved
- Team Captain
- All-Star Selection
- Defensive Player of the Year

## Benefits

✅ **Visibility** - Awards prominently displayed on season page
✅ **Organization** - Separate team vs player awards
✅ **Navigation** - Quick access to player profiles
✅ **Context** - Awards shown in season context
✅ **Recognition** - Highlights achievements
✅ **Professional** - Clean, organized display

## Future Enhancements

Possible improvements:
1. Award categories/types
2. Award voting system
3. Award history across seasons
4. Award statistics
5. Export/share awards
6. Award badges on player cards
7. Award leaderboards
8. Custom award icons per type

---

**Status**: ✅ Complete
**Date**: November 23, 2025
**Breaking Change**: No
**New Tables**: TeamAwards

