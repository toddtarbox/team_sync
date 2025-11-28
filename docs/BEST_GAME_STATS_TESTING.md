# Best Game Stats Caching - Testing Guide

## Quick Test Plan

### 1. Test Initial Cache Build (First Time User)

**Scenario:** User views Best Game stats for the first time

**Steps:**
1. Open the app
2. Navigate to Team → Record Holders
3. Click "Best Game" tab
4. Observe:
   - Progress indicator appears
   - "Building cache..." message shown
   - Stats load after calculation
   - Results display correctly

**Expected Result:**
- Takes 5-20 seconds depending on team size
- Progress updates shown during calculation
- Stats saved to database (check BestGameStats table)
- All categories show correct leaders

**Success Criteria:**
✅ No crashes or OOM errors
✅ Progress indicator visible throughout
✅ Stats appear when complete
✅ Database contains BestGameStats entries

---

### 2. Test Cache Hit (Subsequent Views)

**Scenario:** User views Best Game stats after cache exists

**Steps:**
1. Navigate away from Record Holders view
2. Navigate back to Team → Record Holders
3. Click "Best Game" tab
4. Observe loading time

**Expected Result:**
- Loads in < 1 second
- Shows "Loaded from cache" or completes immediately
- Same stats as before
- No recalculation needed

**Success Criteria:**
✅ Instant/near-instant load
✅ Correct stats displayed
✅ No performance issues

---

### 3. Test Incremental Update (Game Completion)

**Scenario:** Complete a game and verify stats update

**Steps:**
1. Start a new game or open an in-progress game
2. Add events (goals, assists, saves, etc.)
3. Try to set some "best game" performances:
   - Player scores 5+ goals
   - Player makes 10+ saves
   - Player gets 3+ assists
4. Finalize the game (status 9, 10, or 11)
5. Navigate to Record Holders → Best Game
6. Check if new records appear

**Expected Result:**
- Game finalization triggers cache update
- Update completes in background (< 1 second)
- New best performances appear in Best Game view
- Old records preserved if not beaten

**Success Criteria:**
✅ Stats update automatically after game finalized
✅ New records show correct game, player, value
✅ No manual refresh needed
✅ Both home and away team stats updated

---

### 4. Test Cache Rebuild

**Scenario:** Force recalculation of entire cache

**Steps:**
1. In your app, add a debug option to call:
   ```dart
   await team.rebuildBestGameStatsCache(
     progressController: progressController,
   );
   ```
2. Trigger the rebuild
3. Observe progress
4. Verify results match previous cache

**Expected Result:**
- Recalculates all best game stats from scratch
- Shows progress during rebuild
- Overwrites existing cache
- Stats remain consistent

**Success Criteria:**
✅ Rebuild completes without errors
✅ Stats match previous values
✅ Cache updated timestamp changes

---

### 5. Test Large Dataset Performance

**Scenario:** Test with team having 100+ games

**Steps:**
1. Use a team with significant history (or import many games)
2. First view: Time the cache build
3. Second view: Time the cache load
4. Complete a new game
5. Time the incremental update

**Expected Results:**
- Cache build: 10-30 seconds (acceptable for first time)
- Cache load: < 1 second
- Incremental update: < 500ms (background)

**Success Criteria:**
✅ No OOM errors even with 500+ games
✅ Subsequent loads remain fast
✅ Updates don't block UI

---

### 6. Test Edge Cases

#### Empty Team (No Games)
**Steps:**
1. View Best Game for team with no games
2. Should show empty state gracefully

**Expected:** No errors, empty stats display

#### Single Game Team
**Steps:**
1. Team with only 1 game
2. View Best Game stats
3. All records should be from that game

**Expected:** Stats calculated correctly

#### Game Without Events
**Steps:**
1. Game with score but no events (imported game)
2. Stats should skip or show zero

**Expected:** No crashes, graceful handling

#### Concurrent Game Completions
**Steps:**
1. Finalize multiple games quickly
2. Each triggers cache update

**Expected:** All updates complete, last one wins for ties

---

## Database Verification

### Check Cache Exists
```dart
// In Dart/Flutter DevTools or debug console:
final results = await DatabaseService.instance
    .query('BestGameStats', orderByChild: 'teamId', equalTo: YOUR_TEAM_ID);
print('Cache entries: ${results.length}');
```

**Expected:** ~10-15 entries (one per category that has data)

### Check Cache Contents
```dart
for (final entry in results) {
  print('Category: ${entry['category']}, '
        'Player: ${entry['playerId']}, '
        'Value: ${entry['value']}, '
        'Game: ${entry['gameId']}');
}
```

**Expected:** Reasonable values, valid IDs

### Check Last Update Time
```dart
final timestamp = results.first['updatedAt'];
final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
print('Last updated: $date');
```

**Expected:** Recent timestamp after last game completion

---

## Performance Benchmarks

### Target Metrics

| Operation | Target | Acceptable | Poor |
|-----------|--------|------------|------|
| Cache load (hit) | < 500ms | < 1s | > 2s |
| Cache build (miss) | 5-15s | 15-30s | > 30s |
| Incremental update | < 500ms | < 1s | > 2s |
| Memory usage (view) | < 50MB | < 100MB | > 200MB |

### How to Measure

**Time measurements:**
```dart
final stopwatch = Stopwatch()..start();
await team.getBestGameStats();
stopwatch.stop();
print('Load time: ${stopwatch.elapsedMilliseconds}ms');
```

**Memory measurements:**
- Use Android Studio Profiler
- Watch memory graph during operation
- Check for memory leaks after repeated loads

---

## Common Issues & Solutions

### Issue: "table BestGameStats not found"
**Cause:** Database provider doesn't auto-create tables
**Solution:** Table will be created on first insert. Non-fatal error.

### Issue: Stats don't update after game
**Debug:**
```dart
print('Game status: ${game.gameStatus.index}');
print('Should update: ${game.gameStatus.index >= 9}');
```
**Solution:** Ensure endGame() called with status >= 9

### Issue: Slow cache load
**Debug:**
```dart
final stats = await BestGameStats.loadFromDatabase(teamId);
print('Has cache: ${stats.hasCachedStats}');
```
**Solution:** If false, cache is rebuilding. Wait for first build to complete.

### Issue: Wrong stats displayed
**Debug:** Check updatedAt timestamp
**Solution:** Call `team.rebuildBestGameStatsCache()`

---

## Rollback Plan (If Needed)

If caching causes issues, you can temporarily disable it:

**In `team.dart`, modify `getBestGameStats()`:**
```dart
Future<BestGameStats> getBestGameStats({
  StreamController<CalculationProgress>? progressController,
}) async {
  // Temporarily bypass cache - always recalculate
  final data = await fetchAllDataForGame();
  return await calculateBestGameStats(data,
      progressController: progressController);
}
```

This reverts to the old behavior with batch processing (still better than original).

---

## Success Criteria Summary

✅ **First load builds cache** - may take 10-30s, shows progress
✅ **Subsequent loads instant** - < 1s, no recalculation
✅ **Games update cache** - automatic when finalized
✅ **No OOM crashes** - works with 500+ games
✅ **Stats accuracy** - matches manual calculation
✅ **Database persistence** - survives app restart
✅ **Graceful fallback** - recalculates if cache missing/corrupt

---

## Deployment Checklist

Before releasing to production:

- [ ] Test with real team data (100+ games)
- [ ] Verify cache builds on first load
- [ ] Verify instant loads on subsequent views
- [ ] Test game completion updates
- [ ] Check memory usage stays under 100MB
- [ ] Test on low-end Android devices
- [ ] Verify database persistence across app restarts
- [ ] Add analytics to track cache hit rates
- [ ] Document cache rebuild procedure for support
- [ ] Test cache rebuild functionality

---

## Monitoring in Production

Track these metrics:
- Cache hit rate (should be > 95%)
- Average load time (should be < 1s for cache hits)
- Cache rebuild frequency (should be rare)
- Failed updates (should be 0%)

Add logging:
```dart
debugPrint('BestGameStats: Cache hit for team $teamId');
debugPrint('BestGameStats: Cache miss, building for team $teamId');
debugPrint('BestGameStats: Updated after game ${game.id}');
```

