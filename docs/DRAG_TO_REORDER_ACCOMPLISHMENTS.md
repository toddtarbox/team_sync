# Drag-to-Reorder Team Accomplishments

## Feature
Added drag-and-drop functionality for team admins to reorder accomplishments on the team home page. Admins can now easily reorganize accomplishments by dragging them to their desired positions.

## Implementation Date
November 28, 2024

## Changes Made

### File Modified
**`/lib/widgets/team_sync/team_home_page.dart`**

### 1. New Widget Structure
**Before:**
- Static list of accomplishments
- Fixed order based on displayOrder/year/title

**After:**
- `ReorderableListView` for admins (when 2+ items)
- Regular list for non-admins or single items
- Drag handles visible for admin users

### 2. New Methods Added

#### `_buildAccomplishmentCard(TeamAccomplishment accomplishment)`
- Extracted card building logic into reusable method
- Adds drag handle icon for admins
- Same visual appearance as before
- Supports all existing interactions

#### `_onReorderAccomplishments(int oldIndex, int newIndex)`
- Handles drag-and-drop completion
- Updates list order in state
- Saves new displayOrder values to database
- Shows confirmation snackbar

## User Experience

### For Admins (Mobile)

**Visual Indicator:**
```
┌─────────────────────────────────────┐
│ ⋮⋮ 🏆  State Champions       [2024] │ ← Drag handle
│      Division 2 Champions...        │
│                               🔗    │
└─────────────────────────────────────┘
```

**Interaction:**
1. Admin sees drag handle (⋮⋮) on each accomplishment card
2. Admin long presses and drags card up or down
3. Visual feedback shows card being dragged
4. Admin releases to drop in new position
5. Success message appears: "Accomplishments reordered"
6. New order persists across app restarts

### For Non-Admins
- No drag handles visible
- Cards cannot be reordered
- Same viewing experience as before

### Single Item Edge Case
- No reordering available (only one item)
- No drag handle shown
- Cleaner appearance

## Features

### Visual Feedback
✅ **Drag handle** - Clear ⋮⋮ icon indicates draggable items
✅ **Elevation change** - Card lifts during drag
✅ **Gap indication** - Space shows where item will drop
✅ **Smooth animation** - Items smoothly reposition

### Data Persistence
✅ **Automatic saving** - New order saved to database immediately
✅ **DisplayOrder update** - Each accomplishment gets sequential displayOrder (0, 1, 2...)
✅ **Persistent ordering** - Order maintained across app restarts
✅ **Reliable** - Preserves all accomplishment data during reorder

### Smart Display Logic
```dart
if (isAdmin && hasMultipleItems) {
  → ReorderableListView (draggable)
} else {
  → Regular ListView (static)
}
```

## Code Implementation

### ReorderableListView Setup
```dart
ReorderableListView(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  onReorder: _onReorderAccomplishments,
  children: _accomplishments.map((accomplishment) => 
    Padding(
      key: ValueKey(accomplishment.id), // Required for reordering
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildAccomplishmentCard(accomplishment),
    )
  ).toList(),
)
```

### Reorder Handler
```dart
Future<void> _onReorderAccomplishments(int oldIndex, int newIndex) async {
  // Adjust index for drag down
  if (oldIndex < newIndex) {
    newIndex -= 1;
  }

  // Update list order in state
  setState(() {
    final item = _accomplishments.removeAt(oldIndex);
    _accomplishments.insert(newIndex, item);
  });

  // Save new displayOrder to database
  for (int i = 0; i < _accomplishments.length; i++) {
    final accomplishment = _accomplishments[i];
    // Create updated accomplishment with new displayOrder = i
    await updatedAccomplishment.save();
  }
}
```

### Drag Handle
```dart
// Only shown for admins with multiple items
if (isAdmin && hasMultipleItems)
  Icon(
    Icons.drag_indicator,
    color: onSurfaceVariant,
    size: 20,
  ),
```

## Interaction Flow

### Reordering Process
1. **Admin sees list** with drag handles
2. **Long press** on accomplishment card
3. **Drag** card up or down
4. **Visual feedback** shows current position
5. **Release** to drop at new position
6. **List updates** immediately
7. **Database saves** new order
8. **Confirmation** snackbar appears

### Example Reorder
**Before:**
```
0. State Champions (2024)
1. Conference Champions (2023)  
2. 500th Win (2022)
```

**Admin drags item 2 to position 0:**
```
0. 500th Win (2022)              ← displayOrder = 0
1. State Champions (2024)        ← displayOrder = 1
2. Conference Champions (2023)   ← displayOrder = 2
```

## Benefits

### For Admins
✅ **Easy reordering** - Simple drag-and-drop interface
✅ **Visual control** - See changes in real-time
✅ **Override sorting** - Manual control over order
✅ **No manual numbering** - No need to edit displayOrder values
✅ **Quick adjustments** - Instant feedback

### For Users
✅ **Curated order** - Admins can highlight important items
✅ **Better storytelling** - Accomplishments in meaningful sequence
✅ **Consistent experience** - Order maintained across sessions

### For System
✅ **Automatic indexing** - DisplayOrder values auto-assigned (0, 1, 2...)
✅ **Data integrity** - All accomplishment data preserved
✅ **Efficient updates** - Only displayOrder field changes
✅ **No conflicts** - Sequential numbering prevents gaps

## Edge Cases Handled

### Single Accomplishment
- No drag handle shown
- ReorderableListView not used
- Cleaner card appearance
- No confusion about dragging

### Empty List
- Empty state shown (if admin)
- Section hidden (if non-admin)
- No reordering interface

### Non-Admin Users
- Regular ListView used
- No drag handles
- Cannot reorder
- Clean viewing experience

### Web Platform
- Drag-to-reorder disabled (kIsWeb check)
- Regular list view
- Consistent with other web limitations

### Reorder Errors
- Error caught and displayed in snackbar
- List reverts to previous order
- No data loss
- User can retry

## Technical Details

### Key Requirements
**ValueKey:** Each card needs unique key for reordering
```dart
key: ValueKey(accomplishment.id)
```

**DisplayOrder Update:** Sequential assignment based on position
```dart
displayOrder: i // where i is index in list
```

**Physics:** Prevent nested scrolling issues
```dart
physics: const NeverScrollableScrollPhysics()
```

**ShrinkWrap:** Allow in parent scrollable
```dart
shrinkWrap: true
```

### Performance
- **Instant UI update** - setState happens immediately
- **Background save** - Database updates asynchronously
- **Batch operation** - All items saved in sequence
- **Minimal data** - Only displayOrder field updated

## Comparison with Manual Ordering

| Method | Speed | Visibility | Precision |
|--------|-------|------------|-----------|
| **Drag-to-reorder** | Fast | Visual | Exact position |
| **Edit displayOrder** | Slow | Mental math | Number entry |

## Testing Scenarios

- [x] Drag first item to last position
- [x] Drag last item to first position
- [x] Drag middle item up
- [x] Drag middle item down
- [x] Verify displayOrder values updated correctly
- [x] Verify order persists after app restart
- [x] Test with 2 items
- [x] Test with 10+ items
- [x] Verify drag handle only shows for admins
- [x] Verify drag handle hidden for single item
- [x] Test on web (should use regular list)
- [x] Test as non-admin (no drag handles)
- [x] Verify success snackbar appears
- [x] Test error handling (if database fails)

## Future Enhancements

Possible improvements:
1. **Undo reorder** - Quick undo button in snackbar
2. **Drag animation** - More polished drag feedback
3. **Batch drag** - Select and move multiple items
4. **Smart suggestions** - AI-suggested ordering
5. **Templates** - Save and restore order presets
6. **Audit log** - Track reorder history

## Usage Tips

### For Admins
📌 **Pin important items** - Drag most significant accomplishments to top
📅 **Chronological sorting** - Arrange by year for timeline view
🎯 **Story ordering** - Sequence to tell team's journey
🏆 **Trophy case** - Put championships before smaller awards

### Best Practices
1. **Strategic placement** - Most impressive items first
2. **Context matters** - Group related accomplishments
3. **Update regularly** - Reorder as new accomplishments added
4. **User perspective** - Consider what visitors see first

## Summary

Drag-to-reorder provides admins with **intuitive, visual control** over accomplishment ordering:

🎯 **Simple interaction** - Long press and drag
👁️ **Visual feedback** - See changes in real-time
💾 **Automatic saving** - Changes persist immediately
📱 **Mobile-optimized** - Natural touch interface
🔒 **Admin-only** - Controlled access
✨ **Professional UX** - Matches Material Design patterns

**Result:** Admins can now curate the perfect presentation of their team's accomplishments with just a drag! 🏆✨

