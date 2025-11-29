# Team Accomplishments - Quick Reference

## Quick Start

### Add an Accomplishment (Mobile Only, Admin Only)

1. Open team home page
2. Scroll to "Team Accomplishments" section
   - **Note:** This section appears for admins even when empty
   - If no accomplishments exist, you'll see a helpful empty state card
3. Tap the **+** icon in the section header
4. Fill in the form:
   - **Title** (required): e.g., "State Champions"
   - **Description** (optional): Add details
   - **Year** (optional): e.g., 2023
   - **Image URL** (optional): Trophy photo
   - **Link URL** (optional): News article
   - **Display Order** (optional): 0 = first
5. Tap **Add**

### Edit an Accomplishment

1. **Long press** on any accomplishment card
2. Edit the fields
3. Tap **Save**

### Delete an Accomplishment

1. Long press to edit
2. Tap **Delete**
3. Confirm deletion

## Database Table

**Table Name:** `TeamAccomplishments`

**Fields:**
```dart
id: int              // Unique ID
teamId: int          // Team reference
title: string        // Required
description: string? // Optional
imageUrl: string?    // Optional
url: string?         // Optional
year: int?           // Optional
displayOrder: int    // Default: 0
```

## Code Examples

### Query Accomplishments
```dart
final accomplishments = await TeamAccomplishment.listFromTeamId(teamId);
```

### Create Accomplishment
```dart
final accomplishment = TeamAccomplishment(
  id: DateTime.now().millisecondsSinceEpoch,
  teamId: teamId,
  title: 'State Champions',
  year: 2023,
  displayOrder: 0,
);
await accomplishment.save();
```

### Delete Accomplishment
```dart
await accomplishment.delete();
```

## Sorting

Accomplishments are sorted by:
1. **displayOrder** (0 first, then 1, 2, etc.)
2. **year** (newest first: 2024, 2023, 2022...)
3. **title** (alphabetical)

## Common Use Cases

| Accomplishment Type | Example Title | Year | Order |
|---------------------|---------------|------|-------|
| Championship | "State Champions" | 2023 | 0 |
| Milestone | "500th Win" | 2022 | 0 |
| Hall of Fame | "HOF Inductees" | 2024 | 1 |
| Award | "Sportsmanship Award" | 2023 | 2 |
| Record | "15-Game Win Streak" | - | 0 |

## Display Location

Team Home Page (with accomplishments):
```
┌─────────────────────────┐
│ Games Carousel          │
├─────────────────────────┤
│ Overall Record Card     │
├─────────────────────────┤
│ Team Accomplishments ⭐ │ ← NEW
│ - State Champions       │
│ - 500th Win             │
├─────────────────────────┤
│ Seasons                 │
│ - 2024 Season          │
│ - 2023 Season          │
└─────────────────────────┘
```

Team Home Page (empty, admin view):
```
┌─────────────────────────────────────┐
│ Games Carousel                      │
├─────────────────────────────────────┤
│ Overall Record Card                 │
├─────────────────────────────────────┤
│ Team Accomplishments          [+]   │
│ ┌─────────────────────────────────┐ │
│ │     🏆                          │ │
│ │  No team accomplishments yet    │ │
│ │  Tap + to add championships,    │ │
│ │  milestones, and awards         │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Seasons                             │
│ - 2024 Season                       │
└─────────────────────────────────────┘
```

**Note:** Non-admin users won't see the accomplishments section if it's empty.

## Permissions

| Action | Required Permission |
|--------|---------------------|
| View | Everyone (public & users) |
| Add | Team admin (mobile only) |
| Edit | Team admin (mobile only) |
| Delete | Team admin (mobile only) |

## Tips

✅ **DO:**
- Pin important accomplishments (set displayOrder = 0)
- Add years for context
- Include trophy/award images
- Link to news articles or videos
- Keep titles concise
- Add descriptions for context

❌ **DON'T:**
- Add too many accomplishments (be selective)
- Use very long descriptions (2 lines max)
- Forget to add years for dated events
- Include season-specific items (use Team Awards instead)

## Troubleshooting

**Problem:** Add button not showing
**Solution:** Check that you're a team admin and on mobile (not web)

**Problem:** Accomplishments section not visible
**Solution:** 
- For admins: Section always shows with empty state card
- For non-admins: Section only shows if accomplishments exist
- Check that you're logged in and have admin permissions

**Problem:** Image not displaying
**Solution:** Verify image URL is valid and publicly accessible

**Problem:** Accomplishment not saving
**Solution:** Ensure title field is not empty (required)

**Problem:** Wrong sort order
**Solution:** Adjust displayOrder field (0 = first)

## Files Reference

- **Model:** `/lib/models/team_accomplishment.dart`
- **UI:** `/lib/widgets/team_sync/team_home_page.dart`
- **Docs:** `/docs/TEAM_ACCOMPLISHMENTS.md`

## Database Query

```sql
-- Get all accomplishments for team
SELECT * FROM TeamAccomplishments 
WHERE teamId = ?
ORDER BY displayOrder ASC, year DESC, title ASC
```

## API Methods

```dart
// Class: TeamAccomplishment

// Static
TeamAccomplishment.listFromTeamId(int teamId) → Future<List<TeamAccomplishment>>

// Instance
accomplishment.save() → Future<void>
accomplishment.delete() → Future<void>
accomplishment.yearDisplay → String (getter)
accomplishment.displayTitle → String (getter)
```

---

**Quick Example:**

```dart
// Add "State Champions 2023" accomplishment
final accomplishment = TeamAccomplishment(
  id: DateTime.now().millisecondsSinceEpoch,
  teamId: 1,
  title: 'State Champions',
  description: 'Division 2 State Champions',
  year: 2023,
  displayOrder: 0,
  imageUrl: 'https://example.com/trophy.jpg',
  url: 'https://news.example.com/article',
);
await accomplishment.save();
```

**Result on Home Page:**
```
┌──────────────────────────────────────┐
│  🏆  State Champions          [2023] │
│  Division 2 State Champions     🔗   │
└──────────────────────────────────────┘
```

