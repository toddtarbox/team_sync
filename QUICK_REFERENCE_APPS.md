# Quick Reference: TeamSync vs ClubSync

## How to Run Each App

### TeamSync (Single-Team Management)
```bash
# Run TeamSync on mobile
flutter run --target lib/main_team_sync.dart

# Run TeamSync on web
flutter run -d chrome --target lib/main_team_sync.dart

# Build TeamSync for production
flutter build apk --target lib/main_team_sync.dart
flutter build ios --target lib/main_team_sync.dart
flutter build web --target lib/main_team_sync.dart
```

### ClubSync (Multi-Team Club Management)
```bash
# Run ClubSync on mobile
flutter run --target lib/main_club_sync.dart

# Run ClubSync on web
flutter run -d chrome --target lib/main_club_sync.dart

# Build ClubSync for production
flutter build apk --target lib/main_club_sync.dart
flutter build ios --target lib/main_club_sync.dart
flutter build web --target lib/main_club_sync.dart
```

## Key Files by App

### TeamSync Files
- **Entry Point**: `lib/main_team_sync.dart`
- **Router**: `lib/router.dart`
- **Home Page**: `lib/widgets/team_sync/team_home_page.dart`
- **Config**: `AppConfig.teamSync` in `lib/app_config.dart`
- **Firebase**: `lib/firebase_options.dart`

### ClubSync Files
- **Entry Point**: `lib/main_club_sync.dart`
- **Router**: `lib/router_club.dart`
- **Home Page**: `lib/widgets/club_home_page.dart`
- **Team View**: `lib/widgets/home_page.dart` (reused!)
- **Config**: `AppConfig.clubSync` in `lib/app_config.dart`
- **Firebase**: `lib/firebase_options_club.dart`

### Shared Files (Used by Both Apps)
- **Game Entry**: `lib/widgets/responsive/mobile/mobile_game_page.dart`
- **Game Entry (Tablet)**: `lib/widgets/responsive/tablet/tablet_game_page.dart`
- **Season View**: `lib/widgets/season_page.dart`
- **Season Stats**: `lib/widgets/season_stats_page.dart`
- **Players**: `lib/widgets/players_page.dart`
- **Player Profile**: `lib/widgets/player_profile_page.dart`
- **Settings**: `lib/widgets/settings_page.dart`
- **Database Service**: `lib/services/database_service.dart`
- **All Models**: `lib/models/*.dart`

## URL Structures

### TeamSync URLs
```
/                                    → TeamHomePage
/team/{databaseId}                   → TeamHomePage (web viewer)
/team/{databaseId}/season/{id}       → SeasonPage
/team/{databaseId}/season/{id}/game/{id}    → MobileGamePage/TabletGamePage
/team/{databaseId}/season/{id}/players      → PlayersPage
/team/{databaseId}/season/{id}/players/{id} → PlayerProfilePage
/settings                            → SettingsPage
/signin                             → SignInPage
```

### ClubSync URLs
```
/                                    → ClubHomePage (club selection)
/club/{clubId}                       → ClubHomePage (team list)
/club/{clubId}/team/{teamId}         → HomePage (team view)
/club/{clubId}/team/{teamId}/season/{id}           → SeasonPage
/club/{clubId}/team/{teamId}/season/{id}/game/{id} → MobileGamePage/TabletGamePage
/club/{clubId}/team/{teamId}/season/{id}/players   → PlayersPage
/club/{clubId}/team/{teamId}/season/{id}/players/{id} → PlayerProfilePage
/club/{clubId}/stats                 → ClubStatsPage
/club/{clubId}/settings              → SettingsPage (club context)
/settings                            → SettingsPage
/signin                             → SignInPage
```

## Data Storage Paths

### TeamSync Data Structure
```
Firebase Realtime Database:
subscriptionIds/
  {uid}/
    databases/
      {databaseId}/
        Teams/
          {teamId}/
        Seasons/
          {seasonId}/
        Games/
          {gameId}/
        Players/
          {playerId}/
        Events/
          {eventId}/
```

### ClubSync Data Structure
```
Firebase Realtime Database:
Clubs/
  {clubId}/
    
ClubTeams/
  {teamId}/
    clubId: {clubId}
    
ClubSeasons/
  {seasonId}/
    teamId: {teamId}
    
ClubGames/
  {gameId}/
    seasonId: {seasonId}
    
ClubPlayers/
  {playerId}/
    seasonId: {seasonId}
    
ClubEvents/
  {eventId}/
    gameId: {gameId}
```

## Key Differences

| Feature | TeamSync | ClubSync |
|---------|----------|----------|
| **Target Users** | Individual team coaches | Club administrators + parents |
| **Teams Per User** | 1 team | Multiple teams per club |
| **Data Ownership** | User's subscription | Club organization |
| **Database Path** | Nested under user ID | Root-level collections |
| **Authentication** | Optional (local mode) | Required for editing |
| **Sharing** | 6-digit team ID | Club URL or team URL |
| **Mobile Stats** | For own team | For any club team |
| **Admin Features** | Basic settings | Full club management |
| **Subscription** | Required for cloud | Club-level subscription |

## Common Development Tasks

### Add a New Shared Feature
1. Create/modify file in `lib/widgets/` or `lib/widgets/responsive/`
2. Ensure it uses `DatabaseService.instance.query()` for data access
3. Test in both TeamSync and ClubSync
4. No router changes needed if accessed from existing pages

### Add a TeamSync-Only Feature
1. Add to `lib/widgets/team_sync/team_home_page.dart` or create new page
2. Add route to `lib/router.dart` if needed
3. Test with `flutter run --target lib/main_team_sync.dart`

### Add a ClubSync-Only Feature
1. Add to `lib/widgets/club_home_page.dart` or create new page
2. Add route to `lib/router_club.dart` if needed
3. Test with `flutter run --target lib/main_club_sync.dart`

### Debug Database Issues
```dart
// Check current database context
print(DatabaseService.instance.path);
print(DatabaseService.instance.isClubTeam);

// TeamSync should show: subscriptionIds/{uid}/databases/{id}
// ClubSync should show: (empty) with isClubTeam = true
```

### Test Data Loading
```dart
// Both apps use the same query API
final results = await DatabaseService.instance.query(
  'Seasons',
  orderByChild: 'teamId',
  equalTo: teamId,
);

// DatabaseService automatically routes to:
// - TeamSync: subscriptionIds/{uid}/databases/{id}/Seasons/
// - ClubSync: ClubSeasons/
```

## Troubleshooting

### "HomePage not found" error in TeamSync
- Check that `lib/router.dart` imports `team_sync/team_home_page.dart`
- Ensure no routes reference `HomePage` directly
- HomePage is only for ClubSync team views now

### Stats not saving in ClubSync
- Verify `DatabaseService.openClubTeam(clubId, teamId)` was called
- Check that `isClubTeam` flag is true
- Ensure Firebase rules allow writes to ClubGames/ClubPlayers

### Shared pages not working
- Verify the page uses `DatabaseService.instance.query()` not direct Firebase calls
- Check that season/game data is properly loaded before passing to page
- Ensure `await season.load()` is called to load related data

## Testing Checklist

### Before Committing Changes

- [ ] Run `flutter analyze` on modified files
- [ ] Test TeamSync: `flutter run --target lib/main_team_sync.dart`
- [ ] Test ClubSync: `flutter run --target lib/main_club_sync.dart`
- [ ] Verify shared pages work in both apps
- [ ] Check that data saves to correct Firebase paths
- [ ] Test navigation between pages
- [ ] Verify no console errors

### Before Release

- [ ] Build TeamSync for all platforms
- [ ] Build ClubSync for all platforms  
- [ ] Test TeamSync subscription flow
- [ ] Test ClubSync admin features
- [ ] Verify web viewer works for shared teams
- [ ] Test offline mode (TeamSync mobile)
- [ ] Verify Firebase security rules
- [ ] Check analytics are tracking both apps separately

## Resources

- **Main Documentation**: `SEPARATION_IMPLEMENTATION.md`
- **Architecture Diagram**: `docs/ARCHITECTURE_DIAGRAM.md`
- **Firebase Setup**: `docs/FIREBASE.md`
- **Contributing**: `CONTRIBUTING.md`

## Quick Commands

```bash
# Analyze everything
flutter analyze

# Run tests
flutter test

# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean

# Generate app icons
flutter pub run flutter_launcher_icons:main

# Generate splash screens
flutter pub run flutter_native_splash:create
```

