import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';

class GameEditor extends StatefulWidget {
  final Season season;
  final Game? game;
  final Function(Game game, Season season)? onGoToGame;

  const GameEditor({
    super.key,
    required this.season,
    this.game,
    this.onGoToGame,
  });

  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor> {
  late Game _game;
  late int _location; // 0 for Home, 1 for Away
  bool _isLoading = true;
  List<Team> _availableTeams = [];
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _loadTeams();
  }

  void _initializeGame() {
    final team = widget.season.team;
    if (widget.game != null) {
      _game = widget.game!;
      // Determine location based on home/away
      // Note: This logic assumes if we are home team, location is home (0)
      _location = _game.isHomeTeam(widget.season.teamId) ? 0 : 1;
    } else {
      // Default to Home vs generic Opponent if creating new
      // We'll set homeTeam/awayTeam properly once we have the list or defaults
      final now = DateTime.now();
      _game = Game.initial(
        seasonId: widget.season.id,
        homeTeam: team,
        awayTeam: team, // Placeholder
      );
      // Set default time to TBD (midnight)
      _game.date = DateTime(now.year, now.month, now.day, 0, 0);
      _location = 0;
    }
  }

  Future<void> _loadTeams() async {
    try {
      final allTeams = await Team.all();
      setState(() {
        // Filter out current team
        _availableTeams = allTeams
            .where((t) => t.id != widget.season.teamId)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

        _isLoading = false;

        // If new game and we have teams, set a default opponent if needed
        // (though we probably want user to select)
      });
    } catch (e) {
      debugPrint('Error loading teams: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Use a dialog on web/tablet, bottom sheet on mobile usually,
    // but this widget acts as the content.
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: 600, // Limit width on large screens
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.game == null ? loc.addGame : loc.editGame,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),

                    // Opponent Selection
                    Text(
                      loc.opponent,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildOpponentSelector(loc),

                    const SizedBox(height: 24),

                    // Location (Home/Away)
                    Text(
                      "Location",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationToggle(loc),

                    const SizedBox(height: 24),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.date,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _buildDatePicker(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.timeOptional,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _buildTimePicker(context),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Metadata
                    TextFormField(
                      initialValue: _game.description,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) => _game.description = val,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _game.gameLinks,
                      decoration: InputDecoration(
                        labelText: 'Links (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        prefixIcon: const Icon(Icons.link),
                      ),
                      onChanged: (val) => _game.gameLinks = val,
                    ),

                    // Scoreboard preview if editing
                    if (widget.game != null &&
                        _game.id != -1 &&
                        _game.gameStatus != GameStatus.notStarted) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Center(
                        child: ScoreboardWidget(
                          compact: true,
                          game: _game,
                          season: widget.season,
                          teamId: widget.season.teamId,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.onGoToGame != null)
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.sports_soccer),
                            label: Text(loc.goToGame),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.tertiary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onTertiary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close editor
                              widget.onGoToGame!(_game, widget.season);
                            },
                          ),
                        ),
                    ],

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(loc.cancelButton),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(loc.save),
                          ),
                        ),
                      ],
                    ),
                    // Safety details for bottom padding
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOpponentSelector(AppLocalizations loc) {
    // Determine current opponent ID
    int? currentOpponentId;
    if (widget.game != null) {
      if (_location == 0) {
        // Home, so opponent is away
        currentOpponentId = _game.awayTeam.id;
      } else {
        // Away, so opponent is home
        currentOpponentId = _game.homeTeam.id;
      }
      // Handle the case where the opponent might be the same as the current team
      // (initial state/placeholder)
      if (currentOpponentId == widget.season.teamId) {
        currentOpponentId = null;
      }
    }

    final dropdownEntries = _availableTeams.map((t) {
      return DropdownMenuEntry<int>(
        value: t.id,
        label: t.fullName,
      );
    }).toList();

    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
          return DropdownMenu<int>(
            width: constraints.maxWidth,
            initialSelection: currentOpponentId,
            hintText: loc.selectOpponent,
            enableFilter: true,
            requestFocusOnTap: true,
            leadingIcon: const Icon(Icons.search),
            label: Text(loc.selectOpponent),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            dropdownMenuEntries: dropdownEntries,
            onSelected: (teamId) {
              if (teamId == null) return;
              _updateOpponent(teamId);
            },
          );
        }),
        const SizedBox(height: 8),
        if (widget.game == null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.createNewOpponent),
              onPressed: _showCreateOpponentDialog,
            ),
          ),
      ],
    );
  }

  Future<void> _updateOpponent(int teamId) async {
    final opponent = await Team.fromId(teamId);
    if (!mounted) return;

    setState(() {
      if (_location == 0) {
        _game.awayTeam = opponent;
        // Ensure home team is us
        if (_game.homeTeam.id != widget.season.teamId) {
          // We might need to refetch our team, but season.team should be correct
          _game.homeTeam = widget.season.team;
        }
      } else {
        _game.homeTeam = opponent;
        if (_game.awayTeam.id != widget.season.teamId) {
          _game.awayTeam = widget.season.team;
        }
      }
    });
  }

  Widget _buildLocationToggle(AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildLocationOption(loc.home, 0)),
          Expanded(child: _buildLocationOption(loc.away, 1)),
        ],
      ),
    );
  }

  Widget _buildLocationOption(String label, int value) {
    final isSelected = _location == value;
    return GestureDetector(
      onTap: () {
        if (_game.gameStatus.index != 0) {
          return; // Prevent changing if game started (if that rule applies)
        }

        setState(() {
          _location = value;
          // Swap teams
          final temp = _game.homeTeam;
          _game.homeTeam = _game.awayTeam;
          _game.awayTeam = temp;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _game.date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _game.date = DateTime(
              date.year,
              date.month,
              date.day,
              _game.date.hour,
              _game.date.minute,
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _dateFormat.format(_game.date),
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    // Check if time is TBD (midnight)
    final isTbd = _game.date.hour == 0 && _game.date.minute == 0;

    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_game.date),
        );
        if (time != null) {
          setState(() {
            _game.date = DateTime(
              _game.date.year,
              _game.date.month,
              _game.date.day,
              time.hour,
              time.minute,
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatTime12Hour(_game.date),
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isTbd)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _game.date = DateTime(
                      _game.date.year,
                      _game.date.month,
                      _game.date.day,
                      0,
                      0,
                    );
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.close,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime12Hour(DateTime dateTime) {
    if (dateTime.hour == 0 && dateTime.minute == 0) return 'TBD';
    return DateFormat.jm().format(dateTime);
  }

  void _showCreateOpponentDialog() {
    String teamName = '';
    String teamShortName = '';

    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.newTeam),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(labelText: loc.teamName),
                onChanged: (val) => teamName = val,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: loc.teamShortName),
                onChanged: (val) => teamShortName = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                if (teamName.isNotEmpty && teamShortName.isNotEmpty) {
                  Navigator.pop(context);
                  await _saveNewTeam(teamName, teamShortName);
                }
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewTeam(String teamName, String teamShortName) async {
    final newId = DateTime.now().millisecondsSinceEpoch;
    await DatabaseService.instance.insert('Teams', {
      'id': newId,
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': 0, // Transparent
      'color2': 0,
    });

    await _loadTeams(); // Reload list
    _updateOpponent(newId); // Select the new team
  }

  Future<void> _saveGame() async {
    // Basic Validation
    if (_game.homeTeam.id == _game.awayTeam.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an opponent')),
      );
      return;
    }

    try {
      await _game.saveGame();
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate saved
      }
    } catch (e) {
      debugPrint('Error saving game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving game: $e')),
        );
      }
    }
  }
}
