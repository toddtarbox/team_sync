# Navigation Pattern Guide

## Overview

This app uses a platform-aware navigation pattern that automatically adapts to web and mobile platforms using the `NavigationHelper` utility class.

## The Problem

`go_router` provides two main navigation methods:
- **`context.go()`** - Replaces the current route (web-style navigation)
- **`context.push()`** - Pushes a new route onto the stack (mobile-style navigation)

Using `context.go()` everywhere causes poor user experience on mobile devices because:
- ❌ Back button doesn't work as expected
- ❌ Navigation history is lost
- ❌ Users can't navigate back to previous screens

Using `context.push()` everywhere causes issues on web because:
- ❌ Browser URL doesn't update properly
- ❌ Browser back/forward buttons don't work correctly
- ❌ URLs can't be shared or bookmarked effectively

## The Solution: NavigationHelper

The `NavigationHelper` class in `lib/utils/navigation_helper.dart` provides a platform-aware navigation method that:
- ✅ Uses `context.go()` on **web** for URL-based navigation
- ✅ Uses `context.push()` on **mobile** for stack-based navigation
- ✅ Provides consistent API across the entire app

## Usage

### Basic Navigation

Instead of using `context.go()` or `context.push()` directly, use:

```dart
import 'package:team_sync/utils/navigation_helper.dart';

// Navigate to a route (adapts based on platform)
NavigationHelper.navigateTo(
  context,
  '/team/$teamId/season/$seasonId',
  extra: season,
);
```

### When to Use Each Method

#### 1. NavigationHelper.navigateTo() - Most Common

Use for **all standard navigation** where you want platform-appropriate behavior:

```dart
// Navigate to a season
NavigationHelper.navigateTo(
  context,
  '/team/$databaseId/season/${season.id}',
  extra: season,
);

// Navigate to player profile
NavigationHelper.navigateTo(
  context,
  '/team/$databaseId/season/${season.id}/players/${player.id}',
  extra: {'player': player, 'season': season},
);
```

**Behavior:**
- **Web**: Updates URL, replaces current route
- **Mobile**: Pushes new route, maintains back stack

#### 2. NavigationHelper.pushRoute() - Force Push

Use when you **always want to push** regardless of platform (e.g., modals, dialogs):

```dart
// Open a modal or dialog that should always allow going back
NavigationHelper.pushRoute(
  context,
  '/settings/advanced',
);
```

**Behavior:**
- **Web**: Pushes new route (maintains history)
- **Mobile**: Pushes new route (maintains history)

#### 3. NavigationHelper.replaceRoute() - Force Replace

Use when you **always want to replace** regardless of platform (e.g., redirects, logout):

```dart
// Redirect after logout
NavigationHelper.replaceRoute(
  context,
  '/signin',
);
```

**Behavior:**
- **Web**: Replaces current route
- **Mobile**: Replaces current route

## Migration from Direct go_router Calls

### Before (Inconsistent):
```dart
// ❌ Old way - doesn't work well on mobile
context.go('/team/$teamId/season/$seasonId', extra: season);

// ❌ Old way - doesn't work well on web
context.push('/team/$teamId/season/$seasonId', extra: season);
```

### After (Platform-Aware):
```dart
// ✅ New way - works great on both platforms
NavigationHelper.navigateTo(
  context,
  '/team/$teamId/season/$seasonId',
  extra: season,
);
```

## Updated Files

The following files have been updated to use `NavigationHelper`:

- `lib/widgets/season_page.dart` - Season stats and players navigation
- `lib/widgets/players_page.dart` - Player profile navigation
- `lib/widgets/team_sync/team_home_page.dart` - Team, records, history, settings navigation
- `lib/widgets/home_page.dart` - Team loading and navigation
- `lib/widgets/scoreboard_widget.dart` - Game navigation
- `lib/widgets/seasons_list_view.dart` - Season selection
- `lib/widgets/club_home_page.dart` - Club stats, teams, and settings navigation

## Benefits

### For Web Users:
- ✅ URLs update correctly
- ✅ Browser back/forward buttons work
- ✅ Can bookmark and share URLs
- ✅ Refresh page works as expected

### For Mobile Users:
- ✅ Back button works naturally
- ✅ Navigation stack is preserved
- ✅ Intuitive app-like experience
- ✅ Can navigate back through history

## Testing

To test the navigation pattern:

### On Web:
1. Navigate through different screens
2. Verify URL updates in browser address bar
3. Use browser back/forward buttons
4. Refresh the page and verify it loads the correct screen

### On Mobile:
1. Navigate through different screens
2. Use device back button to go back
3. Verify you can navigate back through entire history
4. Check that navigation feels natural and intuitive

## Implementation Details

The `NavigationHelper` uses Flutter's `kIsWeb` constant to detect the platform:

```dart
if (kIsWeb) {
  context.go(location, extra: extra);  // Web: Update URL
} else {
  context.push(location, extra: extra); // Mobile: Maintain stack
}
```

This is evaluated at compile time, so there's no runtime performance impact.

## Future Considerations

If you need to add special navigation behavior:
1. Add a new method to `NavigationHelper`
2. Document the use case in this file
3. Update existing code to use the new method if appropriate

## Related Documentation

- [go_router Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation and Routing](https://docs.flutter.dev/development/ui/navigation)
- [Web URL Strategy](https://docs.flutter.dev/development/ui/navigation/url-strategies)

