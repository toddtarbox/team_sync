# Database Sharing Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    TeamSync Database Sharing                     │
│                                                                  │
│  Enables cross-platform collaboration between Android & iOS     │
│  users with different subscription IDs                          │
└─────────────────────────────────────────────────────────────────┘

## Component Architecture

┌──────────────────────┐      ┌──────────────────────┐
│   Database Owner     │      │    Shared User       │
│   (Pro Subscriber)   │      │   (Any Subscriber)   │
│                      │      │                      │
│  iOS/Apple Sign-In   │      │ Android/Google Auth  │
│  Subscription ID: A  │      │ Subscription ID: B   │
└──────────┬───────────┘      └──────────┬───────────┘
           │                              │
           │ Grants Access                │ Requests Access
           │                              │
           ▼                              ▼
┌────────────────────────────────────────────────────────┐
│            DatabaseSharingService                       │
│  ┌──────────────────────────────────────────────────┐ │
│  │ • grantDatabaseAccess(email, accessLevel)        │ │
│  │ • revokeDatabaseAccess(email)                    │ │
│  │ • checkDatabaseAccess(ownerId, dbName)          │ │
│  │ • getSharedDatabases()                           │ │
│  │ • registerUserInLookup()                         │ │
│  └──────────────────────────────────────────────────┘ │
└────────────────────┬───────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│         Firebase Realtime Database                      │
│                                                         │
│  ┌────────────────────────────────────────────────┐  │
│  │ database_access/{ownerId}/{dbName}/            │  │
│  │   shared_with/{userId}/                        │  │
│  │     - email                                     │  │
│  │     - accessLevel: "read" | "write"            │  │
│  │     - grantedAt                                │  │
│  └────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────────────────────────────────────┐  │
│  │ user_database_access/{userId}/{ownerId}/       │  │
│  │   {dbName}/                                     │  │
│  │     - ownerEmail                                │  │
│  │     - accessLevel                              │  │
│  │     - databasePath                             │  │
│  └────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────────────────────────────────────┐  │
│  │ users/{userId}/                                 │  │
│  │   - email                                       │  │
│  │   - displayName                                │  │
│  │   - photoURL                                   │  │
│  └────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────────────────────────────────────┐  │
│  │ subscriptionIds/{ownerId}/databases/{dbName}/  │  │
│  │   - Teams/                                      │  │
│  │   - Seasons/                                   │  │
│  │   - Players/                                   │  │
│  │   - Games/                                     │  │
│  │   - Events/                                    │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────┐
│              UI Components                              │
│  ┌──────────────────────────────────────────────────┐ │
│  │ DatabaseSharingDialog                            │ │
│  │  - Enter email to share with                     │ │
│  │  - Select access level (read/write)              │ │
│  │  - View who has access                           │ │
│  │  - Revoke access                                 │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │ SharedDatabasesWidget                            │ │
│  │  - Display all databases shared with me          │ │
│  │  - Show owner info and access level              │ │
│  │  - Click to open shared database                 │ │
│  └──────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Flow 1: Granting Access

```
Owner (iOS)                 System                    Shared User (Android)
     │                         │                              │
     │ 1. Click Share          │                              │
     │────────────────────────>│                              │
     │                         │                              │
     │ 2. Enter email          │                              │
     │    "friend@gmail.com"   │                              │
     │────────────────────────>│                              │
     │                         │                              │
     │                         │ 3. Lookup user by email      │
     │                         │    (users table)             │
     │                         │                              │
     │                         │ 4. Create access entry       │
     │                         │    database_access/          │
     │                         │                              │
     │                         │ 5. Create reverse mapping    │
     │                         │    user_database_access/     │
     │                         │                              │
     │ 6. Success!             │                              │
     │<────────────────────────│                              │
     │                         │                              │
     │                         │    7. Database appears       │
     │                         │       in "Shared with Me"    │
     │                         │─────────────────────────────>│
```

### Flow 2: Opening Shared Database

```
Shared User (Android)       System                    Owner's Data
     │                         │                              │
     │ 1. Click on shared DB   │                              │
     │────────────────────────>│                              │
     │                         │                              │
     │                         │ 2. Check access permissions  │
     │                         │    (user_database_access)    │
     │                         │                              │
     │                         │ 3. Verify with Firebase      │
     │                         │    security rules            │
     │                         │                              │
     │                         │ 4. Open database path        │
     │                         │    subscriptionIds/          │
     │                         │    {ownerId}/databases/      │
     │                         │    {dbName}/                 │
     │                         │─────────────────────────────>│
     │                         │                              │
     │                         │    5. Return data            │
     │                         │<─────────────────────────────│
     │                         │                              │
     │ 6. Display data         │                              │
     │<────────────────────────│                              │
```

### Flow 3: Real-Time Sync

```
User A (iOS)                Firebase                  User B (Android)
     │                         │                              │
     │ 1. Add player           │                              │
     │────────────────────────>│                              │
     │                         │                              │
     │                         │ 2. Update database           │
     │                         │    (owner's path)            │
     │                         │                              │
     │                         │    3. Push update            │
     │                         │       (Real-Time sync)       │
     │                         │─────────────────────────────>│
     │                         │                              │
     │                         │    4. Display new player     │
     │                         │                              │
     │    5. User B adds game  │                              │
     │                         │<─────────────────────────────│
     │                         │                              │
     │                         │ 6. Update database           │
     │                         │                              │
     │ 7. Display new game     │                              │
     │<────────────────────────│                              │
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Security Rules                   │
└─────────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
    ┌─────────┐       ┌─────────┐      ┌──────────┐
    │  Owner  │       │  Read   │      │  Write   │
    │  Access │       │  Access │      │  Access  │
    └─────────┘       └─────────┘      └──────────┘
         │                 │                 │
         │                 │                 │
    ✅ Always        ✅ If in            ✅ If accessLevel
    has full        user_database_      === 'write' in
    access          access tree         user_database_access
                                        tree
```

## Permission Matrix

```
┌──────────────┬──────────┬────────────┬─────────────┐
│   Action     │  Owner   │ Read User  │ Write User  │
├──────────────┼──────────┼────────────┼─────────────┤
│ View Data    │    ✅    │     ✅     │     ✅      │
│ Add Records  │    ✅    │     ❌     │     ✅      │
│ Edit Records │    ✅    │     ❌     │     ✅      │
│ Delete Data  │    ✅    │     ❌     │     ✅      │
│ Share Access │    ✅    │     ❌     │     ❌      │
│ Revoke Access│    ✅    │     ❌     │     ❌      │
└──────────────┴──────────┴────────────┴─────────────┘

Note: Only Pro subscribers can grant/revoke access
```

## Technology Stack

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter/Dart                          │
│  ┌───────────────────────────────────────────────────┐ │
│  │ UI Layer                                          │ │
│  │  - DatabaseSharingDialog                          │ │
│  │  - SharedDatabasesWidget                          │ │
│  └───────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Service Layer                                     │ │
│  │  - DatabaseSharingService                         │ │
│  │  - DatabaseService (enhanced)                     │ │
│  │  - SubscriptionService (Pro check)                │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│            Firebase Services                             │
│  ┌────────────────┐  ┌────────────────┐               │
│  │ Firebase Auth  │  │  Realtime DB   │               │
│  │  - iOS/Apple   │  │  - Data storage│               │
│  │  - Android/    │  │  - Real-time   │               │
│  │    Google      │  │    sync        │               │
│  └────────────────┘  └────────────────┘               │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│               RevenueCat                                 │
│  - Pro subscription management                           │
│  - Cross-platform subscription sync                      │
└─────────────────────────────────────────────────────────┘
```

## Cross-Platform Scenario

```
┌─────────────────────────────────────────────────────────────┐
│                    Real-World Example                        │
└─────────────────────────────────────────────────────────────┘

Coach Sarah (iPhone)              Parent Mike (Android)
     iOS App                           Android App
     Apple ID                          Google Account
     Subscription ID: abc123           Subscription ID: xyz789
          │                                   │
          │                                   │
          │ 1. Creates "U12 Soccer Team" DB   │
          │                                   │
          │ 2. Shares with mike@gmail.com     │
          │    Access Level: Write            │
          │                                   │
          │ ─────────────────────────────────>│
          │                                   │
          │                         3. Receives access
          │                         4. Opens shared DB
          │                                   │
          │ 5. Both add player stats          │
          │ <────────Real-Time Sync──────────>│
          │                                   │
          │ 6. Both see updates immediately   │
          │                                   │

Database Path: subscriptionIds/abc123/databases/U12_Soccer_Team.db
Accessed by: Sarah (owner) + Mike (write access)
```

This architecture enables seamless collaboration across platforms! 🚀

