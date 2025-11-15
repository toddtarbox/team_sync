# ClubSync Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLUB MANAGEMENT SYSTEM                       │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐   ┌─────────────┐   │
│  │  ClubHomePage    │───▶│  ClubStatsPage   │   │ HomePage    │   │
│  │                  │    │                  │   │ (Team View) │   │
│  │ • Team Grid      │    │ • Leaders Tab    │   │             │   │
│  │ • Add/Remove     │    │ • Standings Tab  │   │ • Club      │   │
│  │ • Club Info      │    │ • Overview Tab   │   │   Context   │   │
│  └──────────────────┘    └──────────────────┘   └─────────────┘   │
│           │                       │                      │          │
└───────────┼───────────────────────┼──────────────────────┼──────────┘
            │                       │                      │
            │                       │                      │
┌───────────┼───────────────────────┼──────────────────────┼──────────┐
│           │         BUSINESS LOGIC LAYER                 │          │
├───────────┼──────────────────────────────────────────────┼──────────┤
│           ▼                       ▼                      ▼          │
│  ┌──────────────────┐    ┌──────────────────┐   ┌──────────────┐  │
│  │      Club        │    │   ClubStats      │   │    Team      │  │
│  │                  │    │                  │   │              │  │
│  │ • fromId()       │    │ • fromClubId()   │   │ • clubId     │  │
│  │ • all()          │    │ • getTopScorers()│   │   (NEW)      │  │
│  │ • getTeams()     │    │ • getTopAssists()│   │              │  │
│  └──────────────────┘    │ • getStandings() │   └──────────────┘  │
│           │               └──────────────────┘          │          │
│           │                       │                     │          │
│           │       ┌───────────────┴─────────────┐      │          │
│           │       │                             │      │          │
│           │       ▼                             ▼      │          │
│           │  ┌─────────┐  ┌────────┐  ┌─────────────┐ │          │
│           │  │ Player  │  │ Season │  │ GameEvent   │ │          │
│           │  └─────────┘  └────────┘  └─────────────┘ │          │
└───────────┼──────────────────────────────────────────────┼─────────┘
            │                                              │
            │                                              │
┌───────────┼──────────────────────────────────────────────┼─────────┐
│           │              DATA ACCESS LAYER               │         │
├───────────┼──────────────────────────────────────────────┼─────────┤
│           ▼                                              ▼         │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │               DatabaseService (Singleton)                  │   │
│  │                                                            │   │
│  │  • query(table, orderByChild, equalTo)                   │   │
│  │  • insert(table, data)                                    │   │
│  │  • update(table, data, key)                               │   │
│  │  • delete(table, key)                                     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                              │                                     │
│              ┌───────────────┴───────────────┐                    │
│              │                               │                    │
│              ▼                               ▼                    │
│  ┌─────────────────────┐         ┌─────────────────────┐        │
│  │  FirebaseDBProvider │         │ LocalDBProvider     │        │
│  │  (Cloud Storage)    │         │ (SQLite)            │        │
│  └─────────────────────┘         └─────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        DATABASE SCHEMA                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────┐                                                    │
│  │   Clubs     │                                                    │
│  ├─────────────┤                                                    │
│  │ id (PK)     │                                                    │
│  │ name        │                                                    │
│  │ description │                                                    │
│  │ color1      │                                                    │
│  │ color2      │                                                    │
│  │ logoUrl     │                                                    │
│  │ createdAt   │                                                    │
│  └─────────────┘                                                    │
│        │                                                            │
│        │ 1:N                                                        │
│        ▼                                                            │
│  ┌─────────────┐                                                    │
│  │   Teams     │                                                    │
│  ├─────────────┤                                                    │
│  │ id (PK)     │                                                    │
│  │ fullName    │                                                    │
│  │ shortName   │                                                    │
│  │ clubId (FK) │◀───────────────────────────────────────────┐     │
│  │ color1      │                                             │     │
│  │ color2      │                                             │     │
│  │ logoUrl     │                                             │     │
│  └─────────────┘                                             │     │
│        │                                                     │     │
│        │ 1:N                                                 │     │
│        ▼                                                     │     │
│  ┌─────────────┐       ┌─────────────┐                     │     │
│  │  Seasons    │───┐   │   Games     │                     │     │
│  └─────────────┘   │   └─────────────┘                     │     │
│                    │          │                             │     │
│                    │          │ 1:N                         │     │
│                    │          ▼                             │     │
│                    │   ┌─────────────┐                     │     │
│                    │   │   Events    │                     │     │
│                    │   └─────────────┘                     │     │
│                    │                                        │     │
│                    │ 1:N                                    │     │
│                    ▼                                        │     │
│              ┌─────────────┐                               │     │
│              │   Players   │                               │     │
│              └─────────────┘                               │     │
│                                                             │     │
│              Note: clubId is nullable to support            │     │
│                    teams without club affiliation           │     │
│                                                             │     │
└─────────────────────────────────────────────────────────────┘─────┘


┌─────────────────────────────────────────────────────────────────────┐
│                          USER FLOWS                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Flow 1: Create New Club                                            │
│  ┌────────┐   ┌─────────┐   ┌──────────┐   ┌──────────────┐       │
│  │ Launch │──▶│ Click   │──▶│ Enter    │──▶│ View Club    │       │
│  │ App    │   │ Create  │   │ Details  │   │ Dashboard    │       │
│  └────────┘   └─────────┘   └──────────┘   └──────────────┘       │
│                                                                      │
│  Flow 2: Add Team to Club                                           │
│  ┌────────┐   ┌─────────┐   ┌──────────┐   ┌──────────────┐       │
│  │ Club   │──▶│ Click   │──▶│ Select   │──▶│ Team Added   │       │
│  │ Page   │   │ FAB (+) │   │ Team     │   │ to Club      │       │
│  └────────┘   └─────────┘   └──────────┘   └──────────────┘       │
│                                                                      │
│  Flow 3: View Club Statistics                                       │
│  ┌────────┐   ┌─────────┐   ┌──────────┐   ┌──────────────┐       │
│  │ Club   │──▶│ Click   │──▶│ View     │──▶│ Browse       │       │
│  │ Page   │   │ Stats   │   │ Leaders  │   │ Tabs         │       │
│  └────────┘   └─────────┘   └──────────┘   └──────────────┘       │
│                                                                      │
│  Flow 4: Migration (Existing Users)                                 │
│  ┌────────┐   ┌─────────┐   ┌──────────┐   ┌──────────────┐       │
│  │ Launch │──▶│ See     │──▶│ Select   │──▶│ Club         │       │
│  │ App    │   │ Dialog  │   │ Teams    │   │ Created      │       │
│  └────────┘   └─────────┘   └──────────┘   └──────────────┘       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                      ROUTING STRUCTURE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  /                                                                   │
│  └─▶ HomePage (Traditional single-team view)                        │
│                                                                      │
│  /club/:clubId                                                       │
│  └─▶ ClubHomePage                                                   │
│      ├─▶ Team Grid                                                  │
│      ├─▶ Club Statistics                                            │
│      └─▶ Team Management                                            │
│                                                                      │
│  /:databaseId                                                        │
│  └─▶ HomePage (Direct database access)                              │
│                                                                      │
│  /debug-migration                                                    │
│  └─▶ DebugMigrationPage                                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                    STATISTICS CALCULATION FLOW                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ClubStats.fromClubId(clubId)                                       │
│      │                                                               │
│      ├─▶ Get all teams in club                                      │
│      │   └─▶ Query Teams where clubId = clubId                      │
│      │                                                               │
│      ├─▶ For each team:                                             │
│      │   ├─▶ Get all events                                         │
│      │   │   └─▶ Query Events where teamId = teamId                │
│      │   │                                                           │
│      │   ├─▶ Get all games (home & away)                            │
│      │   │   └─▶ Query Games where teamId in [home, away]          │
│      │   │                                                           │
│      │   ├─▶ Calculate team record (W/L/D)                          │
│      │   │                                                           │
│      │   └─▶ Aggregate player statistics                            │
│      │       ├─▶ Goals                                              │
│      │       ├─▶ Assists                                            │
│      │       ├─▶ Shots                                              │
│      │       ├─▶ Saves                                              │
│      │       └─▶ Cards                                              │
│      │                                                               │
│      └─▶ Return ClubStats object                                    │
│          ├─▶ getTopScorers()                                        │
│          ├─▶ getTopAssists()                                        │
│          └─▶ getTeamStandings()                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Relationships

1. **Club ↔ Teams**: One-to-Many (1:N)
   - One club has many teams
   - Each team belongs to at most one club (nullable)

2. **Team ↔ Seasons**: One-to-Many (1:N)
   - One team has many seasons
   - Each season belongs to one team

3. **Season ↔ Games**: One-to-Many (1:N)
   - One season has many games
   - Each game belongs to one season

4. **Game ↔ Events**: One-to-Many (1:N)
   - One game has many events
   - Each event belongs to one game

5. **Team + Season ↔ Players**: Many-to-Many (N:M)
   - Players are scoped to team AND season
   - Composite key: (playerId, teamId, seasonId)

## Data Flow Example

```
User Action: "View top scorers across all teams in club"
│
├─▶ ClubStatsPage requests stats
│   │
│   └─▶ ClubStats.fromClubId(123)
│       │
│       ├─▶ DatabaseService.query('Teams', clubId: 123)
│       │   │
│       │   └─▶ Returns: [Team1, Team2, Team3]
│       │
│       ├─▶ For Team1:
│       │   └─▶ DatabaseService.query('Events', teamId: 1)
│       │       └─▶ Aggregate goals by playerId
│       │
│       ├─▶ For Team2:
│       │   └─▶ DatabaseService.query('Events', teamId: 2)
│       │       └─▶ Aggregate goals by playerId
│       │
│       └─▶ For Team3:
│           └─▶ DatabaseService.query('Events', teamId: 3)
│               └─▶ Aggregate goals by playerId
│
└─▶ ClubStats.getTopScorers(limit: 10)
    │
    ├─▶ Sort all players by goals
    │
    ├─▶ Take top 10
    │
    └─▶ For each playerId:
        └─▶ Player.fromId(playerId)
            └─▶ Returns: Player with displayName
```

