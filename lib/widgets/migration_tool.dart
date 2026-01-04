import 'package:flutter/material.dart';

import 'package:team_sync/services/database_service.dart';

class MigrationTool extends StatefulWidget {
  const MigrationTool({super.key});

  @override
  State<MigrationTool> createState() => _MigrationToolState();
}

class _MigrationToolState extends State<MigrationTool> {
  bool _isMigrating = false;
  String _status = 'Ready to migrate';
  double _progress = 0.0;

  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
      _status = 'Starting migration...';
      _logs.clear();
      _progress = 0.0;
    });

    try {
      // 1. Migrate Players
      _log('Step 1: Fetching players...');
      final playersData =
          await DatabaseService.instance.query('Players') as List?;

      if (playersData == null) {
        _log('No players found.');
      } else {
        final players = playersData.where((p) => p != null).toList();
        _log('Found ${players.length} players. Starting migration...');

        int updatedCount = 0;
        int skippedCount = 0;

        for (int i = 0; i < players.length; i++) {
          final p = players[i];
          final id = p['id'];
          final teamId = p['teamId'];
          final seasonId = p['seasonId'];

          // Check if teamId_seasonId exists
          if (teamId != null && seasonId != null) {
            final expectedKey = '$teamId' '_$seasonId';
            if (p['teamId_seasonId'] != expectedKey) {
              // Use the unique firebase key if available, otherwise fall back to ID (risky)
              final dbKey = p['_key']?.toString() ?? id.toString();
              await DatabaseService.instance.update(
                'Players',
                {'teamId_seasonId': expectedKey},
                key: dbKey,
              );
              updatedCount++;
            } else {
              skippedCount++;
            }
          }

          // Check if id_seasonId exists and is correct (New Optimization)
          if (id != null && seasonId != null) {
            final expectedKey = '${id}_$seasonId';
            if (p['id_seasonId'] != expectedKey) {
              final dbKey = p['_key']?.toString() ?? id.toString();
              await DatabaseService.instance.update(
                'Players',
                {'id_seasonId': expectedKey},
                key: dbKey,
              );
              // Don't double count if we already updated teamId_seasonId for this record
              if (p['teamId_seasonId'] == '$teamId' '_$seasonId') {
                updatedCount++;
              }
            }
          }

          // Update progress for players (first 50%)
          if (i % 10 == 0) {
            setState(() {
              _progress = 0.5 * (i + 1) / players.length;
              _status =
                  'Migrating Players: ${((i + 1) / players.length * 100).toStringAsFixed(0)}%';
            });
          }
        }
        _log(
            'Players Migration Complete. Updated: $updatedCount, Skipped: $skippedCount');
      }

      // 2. Migrate Events
      _log('Step 2: Fetching events...');
      setState(() {
        _status = 'Fetching events...';
      });
      final eventsData =
          await DatabaseService.instance.query('Events') as List?;

      if (eventsData == null) {
        _log('No events found.');
      } else {
        final events = eventsData.where((e) => e != null).toList();
        _log('Found ${events.length} events. Starting migration...');

        int updatedCount = 0;
        int skippedCount = 0;

        for (int i = 0; i < events.length; i++) {
          final e = events[i];
          final id = e['id'];
          final teamId = e['teamId'];
          final seasonId = e['seasonId'];

          // Check if teamId_seasonId exists and migrate
          if (e['teamId_seasonId'] == null &&
              teamId != null &&
              seasonId != null) {
            final key = '$teamId' '_$seasonId';
            final dbKey = e['_key']?.toString() ?? id.toString();
            await DatabaseService.instance.update(
              'Events',
              {'teamId_seasonId': key},
              key: dbKey,
            );
            updatedCount++;
          } else {
            skippedCount++;
          }

          // Update progress for events (second 50%)
          if (i % 10 == 0) {
            setState(() {
              _progress = 0.5 + (0.5 * (i + 1) / events.length);
              _status =
                  'Migrating Events: ${((i + 1) / events.length * 100).toStringAsFixed(0)}%';
            });
          }
        }
        _log(
            'Events Migration Complete. Updated: $updatedCount, Skipped: $skippedCount');
      }

      _log('All Migrations Finished Successfully!');
      setState(() {
        _status = 'Migration Complete';
        _progress = 1.0;
      });
    } catch (e, stack) {
      setState(() {
        _status = 'Error: $e';
      });
      _log('Fatal Error: $e');
      debugPrintStack(stackTrace: stack);
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  void _log(String message) {
    setState(() {
      _logs.add(
          '${DateTime.now().toIso8601String().split('T')[1].split('.')[0]} - $message');
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Migration Tool')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Migrate Players to Compound Keys',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This tool will scan all players and add the "teamId_seasonId" and "id_seasonId" fields to support optimized querying.',
            ),
            const SizedBox(height: 24),
            if (_isMigrating) LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isMigrating ? null : _startMigration,
              child: const Text('Start Migration'),
            ),
            const SizedBox(height: 16),
            const Text('Logs:'),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(_logs[index],
                          style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
