import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

// ---------------------------------------------------------------------------
// Data model: PK stats for one player
// ---------------------------------------------------------------------------
class PenaltyKickPlayerStats {
  final int seasonTaken;
  final int seasonGoals;

  const PenaltyKickPlayerStats({
    required this.seasonTaken,
    required this.seasonGoals,
  });

  static const empty = PenaltyKickPlayerStats(
    seasonTaken: 0,
    seasonGoals: 0,
  );

  String get seasonDisplay => '$seasonGoals / $seasonTaken';

  double get seasonPct =>
      seasonTaken == 0 ? 0.0 : (seasonGoals / seasonTaken).clamp(0.0, 1.0);

  /// Fetches season PK goals/taken for a shooter.
  static Future<PenaltyKickPlayerStats> fetchForShooter(
      int playerId, int teamId, int seasonId) async {
    final seasonEvents =
        await GameEvent.listFromTeamIdSeasonId(teamId, seasonId);
    final seasonPKs = seasonEvents
        .where((e) => e.eventType == 'PenaltyKick' && e.player?.id == playerId)
        .toList();

    return PenaltyKickPlayerStats(
      seasonTaken: seasonPKs.length,
      seasonGoals:
          seasonPKs.where((e) => e.eventData == ShotResult.goal.index).length,
    );
  }

  /// Computes PK save stats for a goalkeeper from already-loaded events.
  static Future<PenaltyKickPlayerStats> fetchForKeeper(
      int keeperId, int teamId, int seasonId) async {
    final seasonEvents =
        await GameEvent.listFromTeamIdSeasonId(teamId, seasonId);

    int seasonSaved = 0;
    int seasonFaced = 0;

    void countForEvents(List<GameEvent> events) {
      final opponentPKs = events
          .where((e) => e.eventType == 'PenaltyKick' && e.team.id == teamId)
          .toList();
      final keeperSaves = events
          .where((e) => e.eventType == 'Save' && e.player?.id == keeperId)
          .toList();

      for (final save in keeperSaves) {
        final saveFacesAPK = opponentPKs.isEmpty
            ? true
            : opponentPKs.any((pk) =>
                pk.game.id == save.game.id &&
                (pk.eventMinute - save.eventMinute).abs() <= 1);
        if (saveFacesAPK) {
          seasonSaved++;
          seasonFaced++;
        }
      }
    }

    countForEvents(seasonEvents);

    return PenaltyKickPlayerStats(
      seasonTaken: seasonFaced,
      seasonGoals: seasonSaved,
    );
  }
}

// ---------------------------------------------------------------------------
// Main overlay widget
// ---------------------------------------------------------------------------

enum _CloseAction { cancel, discard, save }

class PenaltyKickOverlay extends StatefulWidget {
  final PenaltyKick pkEvent;
  final Season season;
  final Game game;
  final Function(PenaltyKick, Player?)? onSaved;
  final VoidCallback? onEditDetails;

  const PenaltyKickOverlay({
    super.key,
    required this.pkEvent,
    required this.season,
    required this.game,
    this.onSaved,
    this.onEditDetails,
  });

  /// Convenience method to show this overlay as a dialog.
  static Future<void> show(
    BuildContext context, {
    required PenaltyKick pkEvent,
    required Season season,
    required Game game,
    Function(PenaltyKick, Player?)? onSaved,
    VoidCallback? onEditDetails,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        bottom: false,
        child: PenaltyKickOverlay(
          pkEvent: pkEvent,
          season: season,
          game: game,
          onSaved: onSaved,
          onEditDetails: onEditDetails,
        ),
      ),
    );
  }

  @override
  State<PenaltyKickOverlay> createState() => _PenaltyKickOverlayState();
}

class _PenaltyKickOverlayState extends State<PenaltyKickOverlay>
    with SingleTickerProviderStateMixin {
  PenaltyKickPlayerStats? _shooterSeasonStats;
  PenaltyKickPlayerStats? _keeperSeasonStats;
  Player? _keeper;
  Player? _shooter;
  late int _resultValue;
  late final Team _shooterTeam;

  late final Player? _initialShooter;
  late final int _initialResultValue;

  bool get _hasUnsavedChanges {
    return _shooter?.id != _initialShooter?.id ||
        _resultValue != _initialResultValue;
  }

  bool _hasShooterPlayers = true;
  bool _hasKeeperPlayers = true;
  bool _loading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initialShooter = widget.pkEvent.player;
    _initialResultValue = widget.pkEvent.eventData;

    _shooter = _initialShooter;
    _resultValue = _initialResultValue;
    _shooterTeam = widget.pkEvent.team;

    _loadStats();
  }

  Future<void> _loadStats() async {
    await _loadSeasonStats();
  }

  Future<void> _loadSeasonStats() async {
    final shooter = _shooter;
    final teamId = widget.season.teamId;
    final seasonId = widget.season.id;

    try {
      final sPlayers =
          await Player.listFromTeamIdSeasonId(widget.pkEvent.team.id, seasonId);
      final kPlayers =
          await Player.listFromTeamIdSeasonId(_getOpponentId(), seasonId);
      if (mounted) {
        setState(() {
          _hasShooterPlayers = sPlayers.isNotEmpty;
          _hasKeeperPlayers = kPlayers.isNotEmpty;
        });
      }
    } catch (_) {}

    PenaltyKickPlayerStats? shooterSeason;
    if (shooter != null && shooter.id > 0) {
      try {
        final seasonEvents =
            await GameEvent.listFromTeamIdSeasonId(teamId, seasonId);
        final pks = seasonEvents
            .where((e) =>
                e.eventType == 'PenaltyKick' && e.player?.id == shooter.id)
            .toList();
        shooterSeason = PenaltyKickPlayerStats(
          seasonTaken: pks.length,
          seasonGoals:
              pks.where((e) => e.eventData == ShotResult.goal.index).length,
        );
      } catch (_) {
        shooterSeason = PenaltyKickPlayerStats.empty;
      }
    }

    Player? keeper = _keeper;
    PenaltyKickPlayerStats? keeperSeason;

    if (keeper == null) {
      final saveEvents = widget.game.allGameEvents
          .where((e) =>
              e.eventType == 'Save' && e.team.id != widget.pkEvent.team.id)
          .toList();

      final pkMinute = widget.pkEvent.eventMinute;
      GameEvent? matchingSave;
      if (saveEvents.isNotEmpty) {
        matchingSave = saveEvents.firstWhere(
          (s) =>
              (pkMinute <= 0 || (s.eventMinute - pkMinute).abs() <= 2) &&
              s.player != null,
          orElse: () => saveEvents.firstWhere(
            (s) => s.player != null,
            orElse: () => saveEvents.first,
          ),
        );
      }

      if (matchingSave != null &&
          matchingSave.eventType == 'Save' &&
          matchingSave.player != null) {
        keeper = matchingSave.player;
      }
    }

    if (keeper != null && keeper.id > 0) {
      try {
        final seasonEvents =
            await GameEvent.listFromTeamIdSeasonId(teamId, seasonId);
        final keeperSaves = seasonEvents
            .where((e) => e.eventType == 'Save' && e.player?.id == keeper!.id)
            .toList();
        keeperSeason = PenaltyKickPlayerStats(
          seasonTaken: keeperSaves.length,
          seasonGoals: keeperSaves.length,
        );
      } catch (_) {
        keeperSeason = PenaltyKickPlayerStats.empty;
      }
    }

    if (mounted) {
      setState(() {
        _shooterSeasonStats = shooterSeason;
        _keeperSeasonStats = keeperSeason;
        _keeper = keeper;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    return PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          final action = await _promptUnsavedAction();
          if (action == _CloseAction.cancel) return;
          if (action == _CloseAction.save) {
            if (mounted) _saveChanges();
          } else if (action == _CloseAction.discard) {
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/jpgs/pk_background.jpg',
                        fit: BoxFit.cover,
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: isCompact
                          ? _buildCompactBody(context)
                          : _buildWideBody(context),
                    ),
                  ),
                  _buildResult(context),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ));
  }

  Future<_CloseAction> _promptUnsavedAction() async {
    final result = await showDialog<_CloseAction>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Unsaved Changes',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Would you like to save them?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_CloseAction.cancel),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_CloseAction.discard),
            child: const Text('Discard',
                style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_CloseAction.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? _CloseAction.cancel;
  }

  void _handleClose() async {
    if (_hasUnsavedChanges) {
      final action = await _promptUnsavedAction();
      if (action == _CloseAction.cancel) return;
      if (action == _CloseAction.save) {
        _saveChanges();
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _buildHeader(BuildContext context) {
    final isUnknownPlayer =
        _shooter == null || _shooter!.lastName.toLowerCase() == 'unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: _handleClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnim.value,
                      child: child,
                    );
                  },
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Penalty Kick',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (!isUnknownPlayer || _shooterTeam.id > 0)
                          Text(
                            _shooterTeam.fullName,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.onEditDetails != null) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon:
                      const Icon(Icons.edit_outlined, color: Color(0xFFFFCC00)),
                  onPressed: widget.onEditDetails,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                  tooltip: 'Edit Details',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    widget.pkEvent.player = _shooter;
    widget.pkEvent.eventData = _resultValue;
    widget.onSaved?.call(widget.pkEvent, _keeper);
    Navigator.of(context).pop();
  }

  Widget _buildCompactBody(BuildContext context) {
    return Column(
      children: [
        _buildPlayerCard(
          context,
          label: 'SHOOTER',
          player: _shooter,
          team: _shooterTeam.shortName,
          seasonStats: _shooterSeasonStats,
          isShooter: true,
          hasTeamPlayers: _hasShooterPlayers,
          icon: Icons.sports_soccer,
          accentColor: const Color(0xFF00C853),
          isLoading: _loading,
        ),
        _buildVsDivider(context),
        _buildPlayerCard(
          context,
          label: 'GOALKEEPER',
          player: _keeper,
          team: _getOpponentName(),
          seasonStats: _keeperSeasonStats,
          isShooter: false,
          hasTeamPlayers: _hasKeeperPlayers,
          icon: Icons.back_hand,
          accentColor: const Color(0xFF2979FF),
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildWideBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildPlayerCard(
              context,
              label: 'SHOOTER',
              player: _shooter,
              team: _shooterTeam.shortName,
              seasonStats: _shooterSeasonStats,
              isShooter: true,
              hasTeamPlayers: _hasShooterPlayers,
              icon: Icons.sports_soccer,
              accentColor: const Color(0xFF00C853),
              isLoading: _loading,
            ),
          ),
          _buildVsDivider(context),
          Expanded(
            child: _buildPlayerCard(
              context,
              label: 'GOALKEEPER',
              player: _keeper,
              team: _getOpponentName(),
              seasonStats: _keeperSeasonStats,
              isShooter: false,
              hasTeamPlayers: _hasKeeperPlayers,
              icon: Icons.back_hand,
              accentColor: const Color(0xFF2979FF),
              isLoading: _loading,
            ),
          ),
        ],
      ),
    );
  }

  String _getOpponentName() {
    final teamId = widget.pkEvent.team.id;
    if (teamId == widget.game.homeTeam.id) {
      return widget.game.awayTeam.shortName;
    }
    return widget.game.homeTeam.shortName;
  }

  Widget _buildVsDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Text(
        'VS',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildPlayerCard(
    BuildContext context, {
    required String label,
    required Player? player,
    required String team,
    required PenaltyKickPlayerStats? seasonStats,
    required bool isShooter,
    required bool hasTeamPlayers,
    required IconData icon,
    required Color accentColor,
    bool isLoading = false,
  }) {
    final hasPlayer = player != null &&
        player.id > 0 &&
        player.lastName.toLowerCase() != 'unknown';
    final cardDecoration = BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
    );

    final canSelect = hasTeamPlayers;

    return InkWell(
      onTap: canSelect ? () => _selectPlayer(isShooter) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLabelChip(label, icon, accentColor),
            const SizedBox(height: 16),
            ResponsiveAvatar(
              imageUrl: hasPlayer ? player.displayImageForStats : null,
              initials: hasPlayer
                  ? '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}'
                  : '',
              size: 44,
              backgroundColor: accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            if (!hasPlayer) ...[
              const SizedBox(height: 4),
              Text(
                canSelect ? 'Tap to Select Player' : team,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                player.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '#${player.number}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                )
              else if (seasonStats != null)
                _buildStatRow(
                  context,
                  isShooter ? 'Season PKs' : 'Season PK Saves',
                  isShooter
                      ? seasonStats.seasonDisplay
                      : '${seasonStats.seasonGoals} / ${seasonStats.seasonTaken}',
                  seasonStats.seasonPct,
                  accentColor,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value,
      double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_resultValue == ShotResult.notInitialized.index) {
      return const SizedBox.shrink();
    }

    final result = ShotResult.values[_resultValue];
    final isGoal = result == ShotResult.goal;
    final isNotSet = result == ShotResult.notInitialized;
    final resultColor = isGoal
        ? const Color(0xFF00C853)
        : (isNotSet ? Colors.grey : Colors.redAccent);
    final resultLabel = isNotSet
        ? 'SELECT RESULT'
        : (isGoal ? '⚽  GOAL!' : result.display.toUpperCase());

    return InkWell(
      onTap: _selectResult,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: resultColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: resultColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Center(
          child: Text(
            resultLabel,
            style: TextStyle(
              color: resultColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectPlayer(bool isShooter) async {
    final teamId = isShooter ? _shooterTeam.id : _getOpponentId();
    final players =
        await Player.listFromTeamIdSeasonId(teamId, widget.season.id);

    if (!mounted) return;

    final selectedPlayer = await showModalBottomSheet<Player>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _buildPlayerSelectionList(players, isShooter ? _shooter : _keeper),
    );

    if (selectedPlayer != null) {
      setState(() {
        if (isShooter) {
          _shooter = selectedPlayer;
        } else {
          _keeper = selectedPlayer;
        }
      });
      _loadSeasonStats();
    }
  }

  int _getOpponentId() {
    return _shooterTeam.id == widget.game.homeTeam.id
        ? widget.game.awayTeam.id
        : widget.game.homeTeam.id;
  }

  Widget _buildPlayerSelectionList(
      List<Player> players, Player? currentPlayer) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Select Player',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected = currentPlayer?.id == player.id;
              return ListTile(
                leading: ResponsiveAvatar(
                  imageUrl: player.displayImageForStats,
                  initials:
                      '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}',
                  size: 32,
                  backgroundColor:
                      const Color(0xFF2979FF).withValues(alpha: 0.3),
                ),
                title: Text(
                  player.displayName,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFCC00) : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFFFFCC00))
                    : null,
                onTap: () => Navigator.of(context).pop(player),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectResult() async {
    final results = [
      ShotResult.goal,
      ShotResult.onTargetSave,
      ShotResult.offTargetPost,
      ShotResult.offTarget,
      ShotResult.onTargetBlock,
    ];

    final selectedResult = await showModalBottomSheet<ShotResult>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Result',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          ...results.map((result) {
            final isSelected = _resultValue == result.index;
            final isGoal = result == ShotResult.goal;
            return ListTile(
              leading: Icon(
                isGoal ? Icons.check_circle : Icons.cancel,
                color: isGoal ? const Color(0xFF00C853) : Colors.redAccent,
              ),
              title: Text(
                result.display,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFCC00) : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFFFFCC00))
                  : null,
              onTap: () => Navigator.of(context).pop(result),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (selectedResult != null) {
      setState(() {
        _resultValue = selectedResult.index;
      });
    }
  }
}
