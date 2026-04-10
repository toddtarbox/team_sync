import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/player_merger_service.dart';

/// Show the player merger tool as a dialog
Future<void> showPlayerMergerDialog(BuildContext context, Team team) {
  return showDialog(
    context: context,
    builder: (context) => PlayerMergerTool(team: team),
  );
}

/// UI for finding and merging duplicate players
class PlayerMergerTool extends StatefulWidget {
  final Team team;

  const PlayerMergerTool({
    super.key,
    required this.team,
  });

  @override
  State<PlayerMergerTool> createState() => _PlayerMergerToolState();
}

class _PlayerMergerToolState extends State<PlayerMergerTool> {
  final PlayerMergerService _mergerService = PlayerMergerService();

  Future<List<DuplicatePlayerGroup>>? _duplicatesFuture;
  List<DuplicatePlayerGroup> _duplicateGroups = [];
  Map<int, Season> _seasons = {};
  String? _statusMessage;
  bool _isCleaningOrphans = false;

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
    _loadSeasons();
  }

  @override
  void dispose() {
    _mergerService.dispose();
    super.dispose();
  }

  Future<void> _loadDuplicates() async {
    final future = _mergerService.findDuplicatePlayers(
      teamId: widget.team.id,
    );

    setState(() {
      _duplicatesFuture = future;
    });

    // Also populate the state variable for the AppBar button
    try {
      final groups = await future;
      setState(() {
        _duplicateGroups = groups;
      });
    } catch (e) {
      debugPrint('Error loading duplicates: $e');
      setState(() {
        _duplicateGroups = [];
      });
    }
  }

  Future<void> _loadSeasons() async {
    final seasonList = await Season.fromTeamId(widget.team.id);
    setState(() {
      _seasons = {for (var s in seasonList) s.id: s};
    });
  }

  Future<void> _cleanupOrphanedEvents() async {
    setState(() {
      _isCleaningOrphans = true;
      _statusMessage = null;
    });

    try {
      // Find orphaned events
      final orphanedEvents =
          await _mergerService.findOrphanedEvents(teamId: widget.team.id);

      if (orphanedEvents.isEmpty) {
        setState(() {
          _statusMessage = 'No orphaned events found!';
          _isCleaningOrphans = false;
        });
        return;
      }

      // Calculate total events
      final totalOrphaned =
          orphanedEvents.values.fold(0, (sum, info) => sum + info.eventCount);

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return AlertDialog(
            title: const Text('Clean Up Orphaned Events'),
            content: Text(
              'Found $totalOrphaned orphaned events from ${orphanedEvents.length} deleted players.\n\n'
              'These events reference players that no longer exist in the database.\n\n'
              'Do you want to delete these orphaned events?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Orphaned Events'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        setState(() {
          _isCleaningOrphans = false;
        });
        return;
      }

      // Delete orphaned events
      final deleted = await _mergerService.deleteOrphanedEvents(orphanedEvents);

      setState(() {
        _statusMessage = 'Successfully deleted $deleted orphaned events!';
        _isCleaningOrphans = false;
      });
    } catch (e) {
      debugPrint('Error cleaning up orphaned events: $e');
      setState(() {
        _statusMessage = 'Error cleaning up orphaned events: $e';
        _isCleaningOrphans = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 900,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Merge Duplicate Players',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.team.fullName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.merge_type),
                    onPressed: _duplicateGroups.isNotEmpty
                        ? () {
                            debugPrint(
                                'Merge All button clicked with ${_duplicateGroups.length} groups');
                            _mergeAllDuplicates(_duplicateGroups);
                          }
                        : null,
                    tooltip: _duplicateGroups.isNotEmpty
                        ? 'Merge All Duplicates'
                        : 'No duplicates to merge',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep),
                    onPressed:
                        _isCleaningOrphans ? null : _cleanupOrphanedEvents,
                    tooltip: 'Clean Up Orphaned Events',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDuplicates,
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // Status message
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _statusMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            // Content
            Expanded(
              child: FutureBuilder<List<DuplicatePlayerGroup>>(
                future: _duplicatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading duplicates: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadDuplicates,
                            child: Text(loc.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final duplicateGroups = snapshot.data ?? [];

                  if (duplicateGroups.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No duplicate players found!',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All players have unique names.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: duplicateGroups.length,
                    itemBuilder: (context, index) {
                      return _buildDuplicateGroupCard(duplicateGroups[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuplicateGroupCard(DuplicatePlayerGroup group) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.people, color: Colors.orange.shade700),
        ),
        title: Text(
          group.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${group.players.length} duplicate records • '
          'Seasons: ${group.seasonIds.join(", ")} • '
          'Numbers: ${group.numbers.join(", ")}',
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select which player record to keep:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...group.players.map((player) {
                  return _buildPlayerOption(player, group);
                }),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _showMergeConfirmation(group);
                      },
                      child: Text(loc.mergeAllIntoFirst),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerOption(Player player, DuplicatePlayerGroup group) {
    final season = _seasons[player.seasonId];
    final seasonName = season?.name ?? 'Season ${player.seasonId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                player.displayNumbers,
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(player.displayName),
        subtitle: Text('$seasonName • Player ID: ${player.id}'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            _showMergeDialog(player, group);
          },
          tooltip: 'Merge others into this player',
        ),
      ),
    );
  }

  void _showMergeDialog(Player primaryPlayer, DuplicatePlayerGroup group) {
    final duplicates =
        group.players.where((p) => p.id != primaryPlayer.id).toList();

    if (duplicates.isEmpty) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.noDuplicatesToMerge)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('Merge Players'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.thisWillMergeFollowingPlayers),
              const SizedBox(height: 12),
              const Text(
                'PRIMARY (Keep):',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text('• ${primaryPlayer.displayName} - '
                  '${_seasons[primaryPlayer.seasonId]?.name ?? "Season ${primaryPlayer.seasonId}"} '
                  '${primaryPlayer.displayNumbers}'),
              const SizedBox(height: 12),
              const Text(
                'DUPLICATES (Merge):',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              ...duplicates.map((p) => Text(
                    '• ${p.displayName} - '
                    '${_seasons[p.seasonId]?.name ?? "Season ${p.seasonId}"} '
                    '${p.displayNumbers}',
                  )),
              const SizedBox(height: 16),
              const Text(
                'All game events, awards, and highlights will be transferred to the primary player. '
                'Duplicate player records will be deleted.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performMerge(primaryPlayer, duplicates);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Merge Players'),
            ),
          ],
        );
      },
    );
  }

  void _showMergeConfirmation(DuplicatePlayerGroup group) {
    if (group.players.isEmpty) return;

    final primaryPlayer = group.players.first;

    _showMergeDialog(primaryPlayer, group);
  }

  Future<void> _performMerge(
      Player primaryPlayer, List<Player> duplicates) async {
    setState(() {
      _statusMessage = 'Merging players...';
    });

    try {
      final result = await _mergerService.mergePlayers(
        primaryPlayer: primaryPlayer,
        duplicatePlayers: duplicates,
        deleteAfterMerge: true,
      );

      setState(() {
        _statusMessage = result.success
            ? 'Successfully merged ${duplicates.length} players. '
                'Updated ${result.totalUpdates} records.'
            : 'Merge failed: ${result.errors.first}';
      });

      if (result.success) {
        // Show detailed results
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(loc.mergeComplete),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Merged ${result.mergedPlayerIds.length} duplicate players'),
                  const SizedBox(height: 8),
                  Text('• Game Events: ${result.eventsUpdated}'),
                  Text('• Awards: ${result.awardsUpdated}'),
                  Text('• Highlights: ${result.highlightsUpdated}'),
                  const SizedBox(height: 8),
                  Text('Duration: ${result.duration.inMilliseconds}ms'),
                  if (result.errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Warnings:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    ...result.errors.map((e) => Text(
                          '• $e',
                          style: const TextStyle(fontSize: 12),
                        )),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadDuplicates(); // Refresh the list
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _mergeAllDuplicates(List<DuplicatePlayerGroup> groups) {
    debugPrint('_mergeAllDuplicates called with ${groups.length} groups');

    if (groups.isEmpty) {
      debugPrint('No groups to merge - returning early');
      return;
    }

    final totalDuplicates = groups.fold<int>(
      0,
      (sum, group) => sum + (group.players.length - 1),
    );

    debugPrint('Total duplicates to merge: $totalDuplicates');

    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('Merge All Duplicates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will merge all ${groups.length} duplicate groups:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...groups.take(5).map((group) {
                final primary = group.players.first;
                final dupes = group.players.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${group.displayName}: $dupes duplicate${dupes > 1 ? "s" : ""} → '
                    '${_seasons[primary.seasonId]?.name ?? "Season ${primary.seasonId}"}',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }),
              if (groups.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... and ${groups.length - 5} more groups',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'What will happen:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• $totalDuplicates duplicate player${totalDuplicates > 1 ? "s" : ""} will be merged',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Each group merges into the first player',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• All events, awards & highlights transferred',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      '• Duplicate records will be deleted',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performMergeAll(groups);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Merge All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performMergeAll(List<DuplicatePlayerGroup> groups) async {
    debugPrint('_performMergeAll called with ${groups.length} groups');

    setState(() {
      _statusMessage = 'Merging all duplicate groups...';
    });

    int totalMerged = 0;
    int totalEvents = 0;
    int totalAwards = 0;
    int totalHighlights = 0;
    final List<String> allErrors = [];
    final startTime = DateTime.now();

    try {
      for (int i = 0; i < groups.length; i++) {
        final group = groups[i];
        debugPrint(
            'Processing group ${i + 1}/${groups.length}: ${group.displayName}');

        if (group.players.isEmpty) {
          debugPrint('  Group has no players - skipping');
          continue;
        }

        final primaryPlayer = group.players.first;
        final duplicates =
            group.players.where((p) => p.id != primaryPlayer.id).toList();

        debugPrint(
            '  Primary: ${primaryPlayer.displayName} (ID: ${primaryPlayer.id})');
        debugPrint('  Duplicates: ${duplicates.length}');

        if (duplicates.isEmpty) {
          debugPrint('  No duplicates to merge - skipping');
          continue;
        }

        setState(() {
          _statusMessage =
              'Merging group ${i + 1}/${groups.length}: ${group.displayName}...';
        });

        final result = await _mergerService.mergePlayers(
          primaryPlayer: primaryPlayer,
          duplicatePlayers: duplicates,
          deleteAfterMerge: true,
        );

        if (result.success) {
          totalMerged += result.mergedPlayerIds.length;
          totalEvents += result.eventsUpdated;
          totalAwards += result.awardsUpdated;
          totalHighlights += result.highlightsUpdated;
        }

        if (result.errors.isNotEmpty) {
          allErrors.addAll(result.errors);
        }
      }

      final duration = DateTime.now().difference(startTime);

      setState(() {
        _statusMessage =
            'Successfully merged $totalMerged players in ${groups.length} groups!';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle,
                    color: allErrors.isEmpty ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                const Text('Merge All Complete'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Successfully processed ${groups.length} duplicate groups:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Merged Players: $totalMerged'),
                        Text('• Game Events Updated: $totalEvents'),
                        Text('• Awards Updated: $totalAwards'),
                        Text('• Highlights Updated: $totalHighlights'),
                        const Divider(height: 20),
                        Text(
                          'Total Updates: ${totalEvents + totalAwards + totalHighlights}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Duration: ${duration.inSeconds}s'),
                      ],
                    ),
                  ),
                  if (allErrors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Warnings:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: allErrors
                            .take(10)
                            .map((e) => Text(
                                  '• $e',
                                  style: const TextStyle(fontSize: 11),
                                ))
                            .toList(),
                      ),
                    ),
                    if (allErrors.length > 10)
                      Text(
                        '... and ${allErrors.length - 10} more warnings',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadDuplicates(); // Refresh the list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during merge all: $e';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Merge Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'An error occurred during the merge:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e.toString()),
                if (totalMerged > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Partial success: $totalMerged players were merged before the error.',
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadDuplicates(); // Refresh the list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
