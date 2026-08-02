import 'package:flutter/material.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';
import 'package:team_sync/features/data_import/services/bound_roster_importer_service.dart';
import 'package:team_sync/features/data_import/services/bound_schedule_importer_service.dart';

import 'package:team_sync/features/data_import/services/data_importer_service.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/games/models/game.dart';

class BoundImportDialog extends StatefulWidget {
  final int teamId;
  final int seasonId;
  final String? seasonYear; // e.g., '2025-26'

  const BoundImportDialog({
    super.key,
    required this.teamId,
    required this.seasonId,
    this.seasonYear,
  });

  @override
  State<BoundImportDialog> createState() => _BoundImportDialogState();
}

class _BoundImportDialogState extends State<BoundImportDialog> {
  final _urlController = TextEditingController();
  final _scheduleImporter = BoundScheduleImporterService();
  final _rosterImporter = BoundRosterImporterService();

  final _dataImporter = DataImporterService();

  // Default URL for convenience
  static const _defaultUrl =
      'https://www.gobound.com/ia/ihsaa/boysbasketball/2025-26/stalbert/v';

  bool _isImporting = false;
  String _statusMessage = '';

  // Season Selection
  List<Season> _seasons = [];
  late int _selectedSeasonId;
  String? _seasonYear;

  // Results
  List<ImportRow>? _rosterRows;
  List<ImportRow>? _scheduleRows;

  ImportResult? _rosterResult;
  ImportResult? _scheduleResult;

  @override
  void initState() {
    super.initState();
    _urlController.text = _defaultUrl;
    _selectedSeasonId = widget.seasonId;
    _seasonYear = widget.seasonYear;
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    try {
      final seasons = await Season.fromTeamId(widget.teamId);
      if (mounted) {
        setState(() {
          _seasons = seasons;
          // If no season selected and we have seasons, default to most recent
          if (_selectedSeasonId == -1 && _seasons.isNotEmpty) {
            _selectedSeasonId = _seasons.first.id;
            _seasonYear = _seasons
                .first.name; // Assuming name is year-like or descriptive
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading seasons: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _dataImporter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Universal Bound Import',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 0. Season Selection (if needed)
            if (_seasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedSeasonId == -1 ? null : _selectedSeasonId,
                  decoration: const InputDecoration(
                    labelText: 'Target Season',
                    border: OutlineInputBorder(),
                    helperText: 'Select the season to import data into.',
                  ),
                  items: _seasons.map((s) {
                    return DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSeasonId = val;
                        // Try to update year hint if possible
                        final s =
                            _seasons.firstWhere((element) => element.id == val);
                        _seasonYear = s.name;
                      });
                    }
                  },
                ),
              ),

            // 1. URL Input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Bound Team Page URL',
                hintText: 'https://www.gobound.com/.../team-name/v',
                border: OutlineInputBorder(),
                helperText:
                    'Paste the main team page URL. We will find Roster, Schedule, and Stats automatically.',
              ),
            ),
            const SizedBox(height: 24),

            // 3. Status / Results Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_statusMessage,
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 16)),
                      ),
                    if (_rosterResult != null)
                      _buildResultTile('Roster', _rosterResult!),
                    if (_scheduleResult != null)
                      _buildResultTile('Schedule', _scheduleResult!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Reset results
                    setState(() {
                      _rosterResult = null;
                      _scheduleResult = null;

                      _statusMessage = '';
                    });
                  },
                  child: const Text('Clear Results'),
                ),
                if (_selectedSeasonId != -1)
                  TextButton(
                    onPressed: _isImporting ? null : _confirmDeleteSeasonData,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete Season Data'),
                  ),
                ElevatedButton(
                  onPressed: _isImporting ? null : _startUniversalImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                  child: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Start Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(String label, ImportResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: result.errorCount > 0 ? Colors.orange[50] : Colors.green[50],
      child: ListTile(
        leading: Icon(
            result.errorCount > 0 ? Icons.warning : Icons.check_circle,
            color: result.errorCount > 0 ? Colors.orange : Colors.green),
        title: Text('$label Import Complete'),
        subtitle: Text(
            'Success: ${result.successCount}, Skipped/Err: ${result.errorCount}'),
      ),
    );
  }

  Future<void> _startUniversalImport() async {
    setState(() {
      _isImporting = true;
      _statusMessage = 'Starting import...';
      _rosterResult = null;
      _scheduleResult = null;
    });

    try {
      final baseUrl = _urlController.text.trim();
      if (baseUrl.isEmpty) throw Exception('Please enter a URL');

      // Normalize URL: remove trailing stuff if it points to a subpage?
      // Heuristic: If it ends in /schedule, /roster, /stats, strip it.
      // But user might paste main page .../v or .../v/

      String cleanUrl = baseUrl;
      if (cleanUrl.endsWith('/')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }

      // If user pasted .../v/schedule, we want .../v
      final knownSuffixes = ['/schedule', '/roster', '/stats'];
      for (final suffix in knownSuffixes) {
        if (cleanUrl.endsWith(suffix)) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - suffix.length);
        }
      }

      // Construct Sub-URLs
      final rosterUrl = '$cleanUrl/roster';
      final scheduleUrl = '$cleanUrl/schedule';

      // Validate Season logic
      if (_selectedSeasonId == -1) {
        throw Exception('Please select a season first.');
      }

      // 1. Roster
      {
        setState(() => _statusMessage = 'Fetching Roster...');
        _rosterRows = await _rosterImporter.parseRoster(
          url: rosterUrl,
          teamId: widget.teamId,
          seasonId: _selectedSeasonId,
        );

        setState(() => _statusMessage =
            'Importing ${_rosterRows!.length} Roster items...');
        _rosterResult = await _dataImporter.importData(
          rows: _rosterRows!,
          fileName: 'Bound Roster Auto',
          entityType: 'Player',
        );
      }

      // 2. Schedule
      {
        setState(() => _statusMessage = 'Fetching Schedule...');
        _scheduleRows = await _scheduleImporter.parseSchedule(
          url: scheduleUrl,
          seasonId: _selectedSeasonId,
          homeTeamId: widget.teamId,
          seasonYear: _seasonYear ?? widget.seasonYear,
        );

        // Split mixed rows (Teams + Games)
        final teamRows =
            _scheduleRows!.where((r) => r.entityType == 'Team').toList();
        final gameRows =
            _scheduleRows!.where((r) => r.entityType == 'Game').toList();

        // Import Opponent Teams first
        if (teamRows.isNotEmpty) {
          setState(() => _statusMessage =
              'Importing ${teamRows.length} Opponent Teams...');
          final teamResult = await _dataImporter.importData(
            rows: teamRows,
            fileName: 'Bound Schedule Opponents',
            entityType: 'Team',
          );

          // Map Opponent Name -> ID
          final opponentIdMap = <String, int>{};
          // Include both successfully imported and skipped rows (if skipped, ID might already exist)
          for (final row in teamResult.successRows) {
            final name = row.data['name'];
            final id = row.data['id'];
            if (name != null && id != null) {
              opponentIdMap[name] = id;
            }
          }
          for (final row in teamResult.skippedRows) {
            final name = row.data['name'];
            final id = row.data['id'];
            if (name != null && id != null) {
              opponentIdMap[name] = id;
            }
          }

          // Fetch existing games to check for duplicates
          final existingGames = await Game.listFromSeasonId(_selectedSeasonId);
          final rowsToRemove = <ImportRow>[];

          // Patch game rows with opponent IDs and check for duplicates
          for (final gameRow in gameRows) {
            final opponentName = gameRow.data['opponentName'];
            if (opponentName != null &&
                opponentIdMap.containsKey(opponentName)) {
              final opponentId = opponentIdMap[opponentName];
              final isHome = gameRow.data['isHome'] == true;
              if (isHome) {
                gameRow.data['awayTeamId'] = opponentId;
              } else {
                gameRow.data['homeTeamId'] = opponentId;
              }
            }

            // Check for duplicate game
            // Match based on Exact Date and Opponent (Home/Away IDs)
            try {
              final newGameDate = DateTime.parse(gameRow.data['date']);
              final newHomeId = gameRow.data['homeTeamId'];
              final newAwayId = gameRow.data['awayTeamId'];

              if (newHomeId != null && newAwayId != null) {
                final isDuplicate = existingGames.any((g) {
                  return g.date.year == newGameDate.year &&
                      g.date.month == newGameDate.month &&
                      g.date.day == newGameDate.day &&
                      g.homeTeam.id == newHomeId &&
                      g.awayTeam.id == newAwayId;
                });

                if (isDuplicate) {
                  rowsToRemove.add(gameRow);
                }
              }
            } catch (e) {
              debugPrint('Error checking duplicate game: $e');
            }
          }

          if (rowsToRemove.isNotEmpty) {
            debugPrint(
                'Skipping ${rowsToRemove.length} existing games to prevent duplicates.');
            for (final r in rowsToRemove) {
              gameRows.remove(r);
            }
            if (mounted) {
              setState(() => _statusMessage =
                  'Skipping ${rowsToRemove.length} existing games...');
            }
          }
        }

        setState(() =>
            _statusMessage = 'Importing ${gameRows.length} Schedule items...');
        _scheduleResult = await _dataImporter.importData(
          rows: gameRows,
          fileName: 'Bound Schedule Auto',
          entityType: 'Game',
        );
      }

      setState(() => _statusMessage = 'All operations completed.');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _confirmDeleteSeasonData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Season Data?'),
        content: const Text(
            'This will permanently delete ALL imported Players, Games, and Stats for the selected season. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isImporting = true;
        _statusMessage = 'Deleting season data...';
      });

      try {
        await _dataImporter.clearSeasonData(_selectedSeasonId);
        setState(() => _statusMessage = 'Season data deleted successfully.');
      } catch (e) {
        setState(() => _statusMessage = 'Error deleting data: $e');
      } finally {
        setState(() => _isImporting = false);
      }
    }
  }
}
