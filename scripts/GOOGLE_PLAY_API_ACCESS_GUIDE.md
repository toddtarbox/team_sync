# Quick Start: Google Play API Access Setup

## 🎯 Fastest Method

**Just go to this URL:**
```
https://play.google.com/console/api-access
```

That's it! No navigation needed.

---

## Step-by-Step with Screenshots Guide

### Current Google Play Console Interface (2024-2025)

```
┌─────────────────────────────────────────────────────┐
│ Google Play Console                          [👤]   │
├─────────────────────────────────────────────────────┤
│                                                      │
│  [≡] Menu                                           │
│   📱 All applications                               │
│   📊 Reports                                        │
│   🌱 Grow                                           │
│   💰 Monetize                                       │
│   📋 Policy                                         │
│   👥 Users and permissions                          │
│   ⋮                                                 │
│   (scroll down)                                     │
│   ⋮                                                 │
│   ⚙️  Settings  ← CLICK HERE                        │
│       └─ Developer account                         │
│       └─ 🔑 API access  ← THEN CLICK HERE          │
│       └─ Account details                           │
│       └─ Email preferences                         │
└─────────────────────────────────────────────────────┘
```

### Alternative Interface (Some Accounts)

```
┌─────────────────────────────────────────────────────┐
│ Google Play Console                          [👤]   │
├─────────────────────────────────────────────────────┤
│  📱 All applications  ← CLICK HERE                  │
│      ├─ App 1                                       │
│      ├─ App 2                                       │
│      └─ Developer account                           │
│          └─ 🔑 API access  ← THEN CLICK HERE       │
└─────────────────────────────────────────────────────┘
```

---

## What You'll See on API Access Page

```
┌─────────────────────────────────────────────────────┐
│ API access                                          │
├─────────────────────────────────────────────────────┤
│                                                      │
│ ☁️ Google Cloud Project                             │
│ ├─ Project: your-project-name                      │
│ └─ [Link] (if not linked yet)                      │
│                                                      │
│ 🤖 Service accounts                                 │
│ ├─ servicename@project.iam.gserviceaccount.com     │
│ │  └─ [Grant access] ← CLICK THIS                  │
│ └─ (your service accounts listed here)             │
│                                                      │
│ 🔐 OAuth clients                                    │
│ └─ (if using OAuth)                                │
└─────────────────────────────────────────────────────┘
```

---

## Grant Access Dialog

When you click "Grant access", you'll see:

```
┌─────────────────────────────────────────────────────┐
│ Invite user                                         │
├─────────────────────────────────────────────────────┤
│                                                      │
│ 📧 Email: servicename@project.iam...               │
│                                                      │
│ 📱 App permissions                                  │
│ └─ [✓] TeamSync (com.tsquared.team_sync.soccer)   │
│                                                      │
│ 👤 Account permissions                              │
│ ├─ [ ] View app information                        │
│ ├─ [✓] Release manager  ← SELECT THIS              │
│ ├─ [ ] Release on production track                 │
│ ├─ [ ] Release on internal testing track only      │
│ └─ ... (other options)                             │
│                                                      │
│ [Cancel]  [Invite user] ← CLICK TO SAVE            │
└─────────────────────────────────────────────────────┘
```

---

## Troubleshooting Checklist

- [ ] I'm logged into the correct Google account
- [ ] I have "Admin" or "Account owner" role
- [ ] I've paid the $25 developer registration fee
- [ ] My account is fully verified
- [ ] I've tried the direct URL: https://play.google.com/console/api-access
- [ ] I've tried clearing browser cache (Cmd+Shift+R / Ctrl+Shift+R)
- [ ] I've tried a different browser or incognito mode
- [ ] I have at least one app created (even in draft)

---

## Quick Command Reference

After setup is complete, use these commands:

```bash
# Build Android app
./scripts/build-team-sync.sh android

# Deploy to Google Play Internal Track
./scripts/deploy-mobile.sh android

# Or do both with version bump
./scripts/bump-and-build.sh patch
# Then answer 'y' when asked to deploy
```

---

## Need More Help?

See the full documentation:
- `scripts/DEPLOY_MOBILE.md` - Complete deployment guide
- `scripts/BUMP_AND_BUILD.md` - Build and version management

Or try:
1. Direct URL: https://play.google.com/console/api-access
2. Google Play Help: https://support.google.com/googleplay/android-developer
3. Check account permissions: https://play.google.com/console/users-and-permissions

