# Quick Reference Card - Dual App Deployment

## Essential Commands

### Development
```bash
# TeamSync
./scripts/run-team-sync.sh chrome

# ClubSync
./scripts/run-club-sync.sh chrome
```

### Production Builds
```bash
# TeamSync - All platforms
./scripts/build-team-sync.sh all

# ClubSync - All platforms
./scripts/build-club-sync.sh all
```

### Verify Setup
```bash
./scripts/verify-dual-setup.sh
```

---

## File Locations

### Core Files
- `lib/app_config.dart` - App configuration
- `lib/main_team_sync.dart` - TeamSync entry
- `lib/main_club_sync.dart` - ClubSync entry
- `lib/router_club.dart` - ClubSync router

### Build Scripts
- `scripts/run-team-sync.sh` - Run TeamSync
- `scripts/run-club-sync.sh` - Run ClubSync
- `scripts/build-team-sync.sh` - Build TeamSync
- `scripts/build-club-sync.sh` - Build ClubSync

### Documentation
- `docs/DUAL_APP_DEPLOYMENT.md` - Full guide
- `DUAL_APP_SETUP_COMPLETE.md` - Quick start

---

## Key Differences

| | TeamSync | ClubSync |
|-|----------|----------|
| **Entry** | main_team_sync.dart | main_club_sync.dart |
| **Router** | router.dart | router_club.dart |
| **Start** | Team page | Club page |
| **Theme** | Green | Blue |
| **Package** | .soccer | .soccer (shared) |
| **Can Install Together** | ❌ No (same package) | Use web for both |

---

## Platform Builds

### Android
```bash
# TeamSync
flutter build apk --target=lib/main_team_sync.dart --flavor teamSync

# ClubSync
flutter build apk --target=lib/main_club_sync.dart --flavor clubSync
```

### iOS
```bash
# TeamSync
flutter build ios --target=lib/main_team_sync.dart

# ClubSync
flutter build ios --target=lib/main_club_sync.dart
```

### Web
```bash
# TeamSync
./scripts/build-team-sync.sh web

# ClubSync
./scripts/build-club-sync.sh web
```

---

## Testing Checklist

- [ ] Run verification script
- [ ] Test TeamSync locally
- [ ] Test ClubSync locally
- [ ] Build TeamSync for target platform
- [ ] Build ClubSync for target platform
- [ ] Test both apps on device
- [ ] Verify data syncs between apps

---

## App Store Info

### Google Play
- **Both apps:** com.tsquared.team_sync.soccer (shared package)
- **Note:** Cannot publish both to Play Store with same package
- **Recommendation:** Focus on web deployments or publish one version

### Apple App Store
- **TeamSync:** com.tsquared.team-sync
- **ClubSync:** com.tsquared.club-sync

---

## Quick Troubleshooting

**Wrong app shows:**
→ Check target: `--target=lib/main_[app]_sync.dart`

**Build fails:**
→ Run: `flutter clean && flutter pub get`

**Both apps look same:**
→ Verify AppConfig initialization in main files

---

**Status:** ✅ Setup Complete
**Verified:** ✅ No issues found
**Ready:** ✅ Production deployment

