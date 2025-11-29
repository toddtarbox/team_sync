# Promoting Season Awards to Team Accomplishments

## Overview

Added the ability to promote season-specific team awards to team-wide accomplishments. This allows significant season achievements to be showcased on the team home page alongside other overall team accomplishments.

## Implementation Date
November 28, 2024

## Feature Description

When a team wins a significant award during a season (e.g., "State Champions", "Conference Champions", "Tournament Winner"), you can now promote that award from the season page to the team home page as a team-wide accomplishment.

## How It Works

### For Users (Team Admins on Mobile)

1. **Navigate to Season Page** - Go to any season that has team awards
2. **Find Team Award** - Look for the team awards section
3. **Click Star Button** - Tap the star icon (⭐) on any team award card
4. **Set Display Order** - Choose where this accomplishment should appear (0 = first)
5. **Confirm** - Tap "Promote"
6. **View** - Optionally tap "View" in the success message to see it on the team home page

### What Gets Promoted

When a team award is promoted:
- **Title** - Copied exactly
- **Description** - Enhanced with season name (e.g., "Won state championship (2024 Season)")
- **Image** - Copied if available
- **External Link** - Copied if available
- **Year** - Extracted from season name (e.g., "2024 Season" → 2024)
- **Display Order** - Set by admin during promotion

### Data Flow

```
Season Award (TeamAward)
    ↓ [Promote Action]
    ↓ [Extract year from season]
    ↓ [Enhance description with season]
    ↓ [Create with new ID]
Team Accomplishment (TeamAccomplishment)
```

## UI Changes

### Season Page - Team Awards Section

**Before:**
```
┌─────────────────────────────┐
│ 🏆 State Champions          │
│    ✏️ Edit    🗑️ Delete      │
└─────────────────────────────┘
```

**After:**
```
┌─────────────────────────────┐
│ 🏆 State Champions          │
│ ⭐ Promote ✏️ Edit 🗑️ Delete │
└─────────────────────────────┘
```

**New Button:**
- Icon: ⭐ (star_border)
- Color: Primary theme color
- Tooltip: "Promote to Team Accomplishment"
- Position: First button (before Edit/Delete)

### Promotion Dialog

```
┌─────────────────────────────────────┐
│ Promote to Team Accomplishment      │
├─────────────────────────────────────┤
│ Promote "State Champions" to a      │
│ team-wide accomplishment?           │
│                                     │
│ This will create a new              │
│ accomplishment on the team home     │
│ page.                               │
│                                     │
│ Display Order: [___0___]            │
│ (0 = show first)                    │
│ Lower numbers appear first          │
│                                     │
│          [Cancel]  [Promote]        │
└─────────────────────────────────────┘
```

### Success Message

```
┌─────────────────────────────────────┐
│ ✓ Promoted to team accomplishment!  │
│                            [View]    │
└─────────────────────────────────────┘
```

Tapping "View" navigates to team home page.

## Implementation Details

### Files Modified

1. **`/lib/models/team_award.dart`**
   - Added import for `TeamAccomplishment`
   - Added `promoteToAccomplishment()` method

2. **`/lib/widgets/season_page.dart`**
   - Added promote button to team award cards
   - Added `_promoteAwardToAccomplishment()` method

### TeamAward.promoteToAccomplishment() Method

```dart
Future<TeamAccomplishment> promoteToAccomplishment({
  int? displayOrder
}) async {
  // Extract year from season name
  final seasonName = await getSeasonName();
  int? year;
  final yearMatch = RegExp(r'(\d{4})').firstMatch(seasonName);
  if (yearMatch != null) {
    year = int.tryParse(yearMatch.group(1)!);
  }

  // Create accomplishment with enhanced description
  final accomplishment = TeamAccomplishment(
    id: DateTime.now().millisecondsSinceEpoch,
    teamId: teamId,
    title: title,
    description: description != null && description!.isNotEmpty
        ? '$description ($seasonName)'
        : seasonName,
    imageUrl: imageUrl,
    url: url,
    year: year,
    displayOrder: displayOrder ?? 0,
  );

  await accomplishment.save();
  return accomplishment;
}
```

**Key Features:**
- Creates new ID to avoid conflicts
- Extracts year from season name using regex
- Enhances description with season context
- Preserves image and URL
- Uses provided display order (defaults to 0)

## Examples

### Example 1: State Championship
**Season Award:**
- Title: "State Champions"
- Description: "Division 2 State Championship"
- Season: "2024 Season"
- Image: trophy.jpg

**Promoted Accomplishment:**
- Title: "State Champions"
- Description: "Division 2 State Championship (2024 Season)"
- Year: 2024
- Image: trophy.jpg
- Display Order: 0 (user sets)

### Example 2: Conference Champions
**Season Award:**
- Title: "Conference Champions"
- Description: null
- Season: "2023 Season"

**Promoted Accomplishment:**
- Title: "Conference Champions"
- Description: "2023 Season"
- Year: 2023
- Display Order: 1 (user sets)

### Example 3: Tournament Winner
**Season Award:**
- Title: "Spring Tournament Champions"
- Description: "Undefeated in tournament"
- Season: "Spring 2024"
- URL: "https://news.com/tournament"

**Promoted Accomplishment:**
- Title: "Spring Tournament Champions"
- Description: "Undefeated in tournament (Spring 2024)"
- Year: 2024 (extracted from "Spring 2024")
- URL: "https://news.com/tournament"
- Display Order: 0

## Year Extraction Logic

The system automatically extracts years from season names:

| Season Name | Extracted Year |
|-------------|----------------|
| "2024 Season" | 2024 |
| "Spring 2023" | 2023 |
| "2022-2023" | 2022 (first match) |
| "Fall Season" | null (no year) |
| "2025" | 2025 |

Uses regex pattern: `(\d{4})` to find 4-digit years.

## Display Order Guidelines

**Recommended Display Orders:**
- **0** - Most prestigious (State Champions, National Champions)
- **1** - Major achievements (Conference Champions, Regional Champions)
- **2** - Tournament wins
- **3** - Special recognitions
- **4+** - Other accomplishments

Lower numbers appear first on the team home page.

## Workflow Example

### Complete User Journey

1. **Season 2024 ends** - Team wins State Championship
2. **Admin adds season award** on season page:
   - Title: "State Champions"
   - Description: "Undefeated season, state title"
   - Image: Trophy photo
3. **Admin promotes award**:
   - Clicks ⭐ button
   - Sets display order = 0 (show first)
   - Confirms promotion
4. **Accomplishment created** on team home page:
   - Appears at top (display order 0)
   - Shows year badge [2024]
   - Includes enhanced description
   - Displays trophy image
5. **Visitors see accomplishment** prominently on team home

## Differences from Manual Creation

| Aspect | Manual Creation | Promotion |
|--------|----------------|-----------|
| **Speed** | Slower (fill all fields) | Faster (data copied) |
| **Year** | Manual entry | Auto-extracted |
| **Description** | Manual entry | Auto-enhanced |
| **Season context** | Must add manually | Added automatically |
| **Use case** | New accomplishments | Season awards |

## Best Practices

### When to Promote

✅ **DO promote:**
- Championship wins (state, conference, tournament)
- Undefeated seasons
- Major titles and trophies
- Record-breaking seasons
- Significant milestones tied to a season

❌ **DON'T promote:**
- Individual player awards (those stay on season page)
- Regular season records (unless record-breaking)
- Minor tournaments
- Routine accomplishments

### Display Order Strategy

```
Display Order 0: Championships & Titles
  - State Champions (2024)
  - National Tournament Winners (2022)

Display Order 1: Conference & Regional
  - Conference Champions (2023)
  - Regional Champions (2024)

Display Order 2: Tournaments
  - Spring Tournament (2024)
  - Holiday Classic (2023)

Display Order 3+: Other
  - Perfect Season (2022)
  - Sportsmanship Award (2023)
```

## Technical Notes

### Data Independence

- Promoted accomplishment is **independent** of original award
- Deleting the season award does NOT delete the accomplishment
- Editing the season award does NOT update the accomplishment
- This is intentional - accomplishments are meant to be permanent

### ID Generation

```dart
id: DateTime.now().millisecondsSinceEpoch
```

Uses current timestamp to ensure unique IDs and avoid conflicts with existing accomplishments or awards.

### Season Name Parsing

Robust year extraction handles various season name formats:
- "2024 Season"
- "Fall 2024"
- "2023-2024"
- "Spring Season 2024"

Always finds the first 4-digit number that looks like a year.

## Permissions

| Action | Required Permission |
|--------|---------------------|
| **View promoted button** | Team admin (mobile only) |
| **Promote award** | Team admin (mobile only) |
| **View accomplishment** | Everyone |

Same permission model as other admin features.

## Future Enhancements

Possible improvements:
1. **Bulk promotion** - Promote multiple awards at once
2. **Promotion history** - Track which awards were promoted
3. **Sync updates** - Option to keep accomplishment synced with award
4. **Un-promote** - Reverse the promotion (delete accomplishment)
5. **Smart defaults** - Auto-suggest display order based on award type
6. **Preview** - Show how accomplishment will look before promoting
7. **Duplicate detection** - Warn if similar accomplishment exists

## Testing Checklist

- [ ] Create a team award in a season
- [ ] Click the ⭐ promote button
- [ ] Set display order to 0
- [ ] Confirm promotion
- [ ] Verify success message appears
- [ ] Click "View" to navigate to team home
- [ ] Verify accomplishment appears on team home
- [ ] Check year badge displays correctly
- [ ] Verify description includes season name
- [ ] Check image displays correctly
- [ ] Test with award that has no description
- [ ] Test with season name without year
- [ ] Test with different display orders
- [ ] Verify promote button hidden for non-admins
- [ ] Test on web (button should be hidden)
- [ ] Edit original award, verify accomplishment unchanged
- [ ] Delete original award, verify accomplishment remains

## Migration & Compatibility

### No Database Changes
- Uses existing `TeamAccomplishments` table
- No schema migrations needed
- Backwards compatible

### For Existing Teams
- Can promote any existing team awards
- Works with awards from old seasons
- Year extraction works on historical data

## Summary

The promotion feature provides a **quick and easy way** to elevate season-specific achievements to team-wide recognition. Instead of manually re-creating important awards as accomplishments, admins can simply click the star button to promote them, automatically preserving all the details and adding season context.

**Key Benefits:**
✅ **One-click promotion** from season to team-wide
✅ **Automatic year extraction** from season name
✅ **Enhanced descriptions** with season context
✅ **Preserves images and links** from original award
✅ **Flexible display ordering** for proper prominence
✅ **Independent data** - promoted items stand alone
✅ **Simple UX** - star button with confirmation dialog
✅ **Smart defaults** - sensible values for all fields

This feature bridges the gap between season-specific achievements and team-wide legacy! 🏆⭐

