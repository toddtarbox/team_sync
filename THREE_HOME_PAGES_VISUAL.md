# Three Home Pages - Visual Guide

## The Three Home Pages at a Glance

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  📱 TEAMSYNC APP                                                     │
│                                                                      │
│  Entry: main_team_sync.dart → router.dart                           │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  HOME PAGE #1: TeamHomePage                                 │    │
│  │  📄 File: lib/widgets/team_sync/team_home_page.dart        │    │
│  │                                                              │    │
│  │  Purpose: Single-team database management                   │    │
│  │                                                              │    │
│  │  🎯 Create/Open Database                                    │    │
│  │  🎯 View Single Team                                        │    │
│  │  🎯 Manage Subscriptions                                    │    │
│  │  🎯 Share Team (6-digit ID)                                 │    │
│  │  🎯 Web Viewer Mode                                         │    │
│  │                                                              │    │
│  │  Parameters: databaseId (optional)                          │    │
│  │                                                              │    │
│  │  Routes:                                                     │    │
│  │  • / (root)                                                 │    │
│  │  • /team/:databaseId (web viewer)                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │           SHARED PAGES (used by both apps)                  │    │
│  │  • SeasonPage                                               │    │
│  │  • MobileGamePage / TabletGamePage                          │    │
│  │  • PlayersPage / PlayerProfilePage                          │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  🏢 CLUBSYNC APP                                                     │
│                                                                      │
│  Entry: main_club_sync.dart → router_club.dart                      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  HOME PAGE #2: ClubHomePage                                 │    │
│  │  📄 File: lib/widgets/club_home_page.dart                   │    │
│  │                                                              │    │
│  │  Purpose: Club selection and team grid                      │    │
│  │                                                              │    │
│  │  🎯 Select/Create Club                                      │    │
│  │  🎯 Display Team Grid                                       │    │
│  │  🎯 Club-wide Statistics                                    │    │
│  │  🎯 Admin Management                                        │    │
│  │  🎯 Create Teams                                            │    │
│  │                                                              │    │
│  │  Parameters: clubId (optional)                              │    │
│  │                                                              │    │
│  │  Routes:                                                     │    │
│  │  • / (club selection)                                       │    │
│  │  • /club/:clubId (team grid)                                │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ↓ (user selects team)                   │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │  HOME PAGE #3: HomePage                                     │    │
│  │  📄 File: lib/widgets/home_page.dart                        │    │
│  │                                                              │    │
│  │  Purpose: Team view within club context                     │    │
│  │                                                              │    │
│  │  🎯 Display Team in Club                                    │    │
│  │  🎯 Open Club Team DB Context                               │    │
│  │  🎯 Navigate to Club Features                               │    │
│  │  🎯 Handle Club Permissions                                 │    │
│  │                                                              │    │
│  │  Parameters: teamId, clubId, club                           │    │
│  │                                                              │    │
│  │  Routes:                                                     │    │
│  │  • /club/:clubId/team/:teamId                               │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ↓                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │           SHARED PAGES (used by both apps)                  │    │
│  │  • SeasonPage                                               │    │
│  │  • MobileGamePage / TabletGamePage                          │    │
│  │  • PlayersPage / PlayerProfilePage                          │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Side-by-Side Comparison

| Aspect | TeamHomePage | ClubHomePage | HomePage |
|--------|-------------|--------------|----------|
| **App** | TeamSync | ClubSync | ClubSync |
| **Level** | Team Management | Club Management | Team in Club |
| **File** | `team_sync/team_home_page.dart` | `club_home_page.dart` | `home_page.dart` |
| **Route** | `/` or `/team/:id` | `/` or `/club/:id` | `/club/:id/team/:id` |
| **Shows** | Database + Team + Seasons | Clubs + Teams Grid | Team + Seasons (in club) |
| **Creates** | Database, Team, Season | Club, Teams | Nothing (view only) |
| **Auth** | Optional | Required for editing | Required for editing |
| **Subscription** | ✅ Required | ✅ Club-level | ❌ N/A |
| **Database** | Opens TeamSync DB | No database | Opens club team context |
| **Parameters** | `databaseId` | `clubId` | `teamId`, `clubId`, `club` |

## User Journeys

### TeamSync Journey
```
Mobile App Launch
       ↓
   TeamHomePage (/)
       |
       ├─ No Database?
       |      ↓
       |  Show "Create Database"
       |      ↓
       |  User creates database
       |      ↓
       |  Show "Create Team"
       |      ↓
       |  User creates team
       |      ↓
       └─ Has Database & Team?
              ↓
          Show Seasons List
              ↓
          User taps season
              ↓
          SeasonPage (shared)
              ↓
          User taps game
              ↓
          MobileGamePage (shared)
```

### ClubSync Journey
```
Mobile App Launch
       ↓
   ClubHomePage (/)
       ↓
   Show Club Selection
       ↓
   User selects club
       ↓
   ClubHomePage (/club/:id)
       ↓
   Show Team Grid
       ↓
   User taps team card
       ↓
   HomePage (/club/:id/team/:id)
       ↓
   Show Team Seasons
       ↓
   User taps season
       ↓
   SeasonPage (shared)
       ↓
   User taps game
       ↓
   MobileGamePage (shared)
```

## Code Organization

```
lib/widgets/
├── team_sync/
│   └── team_home_page.dart     ← HOME PAGE #1 (TeamSync)
├── home_page.dart               ← HOME PAGE #3 (ClubSync team view)
├── club_home_page.dart          ← HOME PAGE #2 (ClubSync club view)
├── season_page.dart             ← SHARED
├── players_page.dart            ← SHARED
├── player_profile_page.dart     ← SHARED
└── responsive/
    ├── mobile/
    │   └── mobile_game_page.dart  ← SHARED
    └── tablet/
        └── tablet_game_page.dart  ← SHARED
```

## When to Edit Which File

### I want to change how users create databases
→ Edit `team_sync/team_home_page.dart`

### I want to change the club selection screen
→ Edit `club_home_page.dart`

### I want to change how teams are displayed in the grid
→ Edit `club_home_page.dart`

### I want to change how a team looks when viewing it in a club
→ Edit `home_page.dart`

### I want to change how seasons are displayed
→ Edit `season_page.dart` (affects BOTH apps!)

### I want to change how game stats are entered on mobile
→ Edit `responsive/mobile/mobile_game_page.dart` (affects BOTH apps!)

### I want to add a TeamSync-only feature
→ Edit `team_sync/team_home_page.dart` or create new file in `team_sync/`

### I want to add a ClubSync-only feature (club-level)
→ Edit `club_home_page.dart` or create new file

### I want to add a ClubSync-only feature (team-level)
→ Edit `home_page.dart` or create new file

### I want to add a feature for both apps
→ Create new shared component or edit existing shared page

## Quick Reference

```
┌─────────────────────┬──────────────────────┬─────────────────────┐
│   TeamHomePage      │    ClubHomePage      │     HomePage        │
├─────────────────────┼──────────────────────┼─────────────────────┤
│ Single-team mgmt    │ Multi-club dashboard │ Team in club view   │
│ Database creation   │ Team grid            │ Season navigation   │
│ Subscription UI     │ Club selection       │ Club branding       │
│ Web viewer          │ Admin features       │ Permission handling │
│ Share team ID       │ Create clubs/teams   │ Navigate to club    │
├─────────────────────┼──────────────────────┼─────────────────────┤
│ USED BY: TeamSync   │ USED BY: ClubSync    │ USED BY: ClubSync   │
└─────────────────────┴──────────────────────┴─────────────────────┘
```

## Summary

✅ **3 home pages is the correct architecture!**

Each serves a unique, focused purpose:
- **TeamHomePage**: TeamSync database and team management
- **ClubHomePage**: ClubSync club selection and overview  
- **HomePage**: ClubSync team view within club context

This provides:
- ✅ Clear separation of concerns
- ✅ Minimal code duplication
- ✅ Easy to maintain and extend
- ✅ No conditional logic chaos
- ✅ Maximum reuse of shared components

**The architecture is working perfectly! 🎉**

