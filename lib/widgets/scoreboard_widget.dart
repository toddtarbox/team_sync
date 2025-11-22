import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

class ScoreboardWidget extends StatefulWidget {
  final Game? game;
  final Season? season;
  final int teamId;
  final bool compact;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const ScoreboardWidget({
    Key? key,
    required this.game,
    required this.season,
    required this.teamId,
    this.compact = false,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  State<ScoreboardWidget> createState() => _ScoreboardWidgetState();
}

class _ScoreboardWidgetState extends State<ScoreboardWidget> {
  Timer? _updateTimer;
  Game? _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _setupAutoUpdate();
  }

  @override
  void didUpdateWidget(ScoreboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game?.id != widget.game?.id) {
      _currentGame = widget.game;
      _setupAutoUpdate();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _setupAutoUpdate() {
    _updateTimer?.cancel();

    if (isLiveGame) {
      // Update every 5 seconds during live games
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        await _reloadGameData();
      });
    }
  }

  Future<void> _reloadGameData() async {
    if (_currentGame == null) return;

    try {
      await _currentGame!.loadGameEvents();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
      debugPrint('Error reloading game data: $e');
    }
  }

  bool get isLiveGame {
    if (_currentGame == null) return false;
    return _currentGame!.gameStatus.index > 0 &&
        _currentGame!.gameStatus.index < 9;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine sizing based on available space and compact mode
        final isCompact = widget.compact || constraints.maxHeight < 150;
        final effectiveMargin = widget.margin ??
            (isCompact ? EdgeInsets.zero : const EdgeInsets.all(16.0));
        final effectivePadding = widget.padding ??
            (isCompact
                ? const EdgeInsets.all(8.0)
                : const EdgeInsets.all(16.0));

        // Scale font sizes based on compact mode
        final scoreFontSize = isCompact ? 32.0 : 48.0;
        final teamNameFontSize = isCompact ? 12.0 : 16.0;
        final headerFontSize = isCompact ? 11.0 : 14.0;
        final descriptionFontSize = isCompact ? 11.0 : 13.0;
        final avatarSize = isCompact ? 32.0 : 48.0;
        final verticalSpacing = isCompact ? 4.0 : 8.0;
        final sectionSpacing = isCompact ? 8.0 : 16.0;

        if (_currentGame == null) {
          return Card(
            margin: effectiveMargin,
            child: Padding(
              padding: effectivePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: isCompact ? 32 : 48,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  SizedBox(height: verticalSpacing),
                  Text(
                    'No games yet',
                    style: TextStyle(
                      fontSize: teamNameFontSize,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final leftTeam = _currentGame!.homeTeam;
        final rightTeam = _currentGame!.awayTeam;
        final leftScore = _currentGame!.homeTeamScore;
        final rightScore = _currentGame!.awayTeamScore;

        // Determine if user's team won/lost/tied
        final isWin = _currentGame!.isWin(widget.teamId);
        final isTie = _currentGame!.isTie;
        final isLoss = !isWin && !isTie && _currentGame!.gameStatus.index >= 9;

        // Check which team is the user's team for highlighting
        final isLeftTeamMine = leftTeam.id == widget.teamId;
        final isRightTeamMine = rightTeam.id == widget.teamId;

        return Card(
          margin: effectiveMargin,
          elevation: isLiveGame ? 10 : 8,
          shadowColor: isLiveGame ? Colors.amber.withOpacity(0.5) : null,
          child: InkWell(
            onTap: widget.season != null
                ? () {
                    final databaseId = DatabaseService.instance.publicShareId;
                    if (databaseId != null) {
                      final targetRoute =
                          '/team/$databaseId/season/${widget.season!.id}/game/${_currentGame!.id}';
                      final currentRoute = GoRouterState.of(context).uri.path;

                      // Only navigate if not already on this game's route
                      if (currentRoute != targetRoute) {
                        NavigationHelper.navigateTo(
                          context,
                          targetRoute,
                          extra: {
                            'season': widget.season,
                            'game': _currentGame,
                          },
                        );
                      }
                    }
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF2a2a2a),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isLiveGame
                      ? Colors.amber.withOpacity(0.6)
                      : Colors.grey.withOpacity(0.3),
                  width: isLiveGame ? 2 : 1,
                ),
                boxShadow: isLiveGame
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: effectivePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with status
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: isCompact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isLiveGame)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 8 : 12,
                                  vertical: isCompact ? 2 : 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.circular(isCompact ? 8 : 12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: isCompact ? 6 : 8,
                                    height: isCompact ? 6 : 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: isCompact ? 4 : 6),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isCompact ? 10 : 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                DateFormat(isCompact ? 'MMM d' : 'MMM d, yyyy')
                                    .format(_currentGame!.date),
                                style: TextStyle(
                                  fontSize: headerFontSize,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              _currentGame!.gameStatus.display,
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.bold,
                                color: isLiveGame
                                    ? Colors.greenAccent
                                    : Colors.amber,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    // Score display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Home team (left)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLeftTeamMine
                                    ? Colors.amber.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.2),
                                width: isLeftTeamMine ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isCompact)
                                  Text(
                                    'HOME',
                                    style: TextStyle(
                                      fontSize: headerFontSize * 0.7,
                                      color: Colors.amber.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                if (!isCompact)
                                  SizedBox(height: verticalSpacing / 2),
                                if (leftTeam.logoUrl != null &&
                                    leftTeam.logoUrl!.isNotEmpty)
                                  SizedBox(
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: ResponsiveAvatar(
                                      imageUrl: leftTeam.logoUrl,
                                      backgroundColor:
                                          leftTeam.color1.withOpacity(0.2),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: ResponsiveAvatar(
                                      initials: leftTeam.shortName.isNotEmpty
                                          ? leftTeam.shortName[0]
                                          : null,
                                      backgroundColor:
                                          leftTeam.color1.withOpacity(0.2),
                                      fallbackIcon: Icon(
                                        Icons.sports_soccer,
                                        color: leftTeam.color1,
                                        size: avatarSize * 0.6,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: verticalSpacing),
                                Text(
                                  leftTeam.shortName,
                                  style: TextStyle(
                                    fontSize: teamNameFontSize,
                                    fontWeight: isLeftTeamMine
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Score
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 12.0 : 20.0,
                            vertical: isCompact ? 8.0 : 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Left score
                                  Container(
                                    constraints: BoxConstraints(
                                      minWidth: isCompact ? 40 : 60,
                                    ),
                                    child: Text(
                                      leftScore.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: scoreFontSize,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: isLeftTeamMine &&
                                                isWin &&
                                                !isLiveGame
                                            ? const Color(0xFF00FF00)
                                            : isLeftTeamMine &&
                                                    isLoss &&
                                                    !isLiveGame
                                                ? const Color(0xFFFF0000)
                                                : const Color(0xFFFFD700),
                                        shadows: [
                                          Shadow(
                                            color: isLeftTeamMine &&
                                                    isWin &&
                                                    !isLiveGame
                                                ? const Color(0xFF00FF00)
                                                : isLeftTeamMine &&
                                                        isLoss &&
                                                        !isLiveGame
                                                    ? const Color(0xFFFF0000)
                                                    : const Color(0xFFFFD700),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Separator
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 6.0 : 12.0),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        fontSize: scoreFontSize * 0.8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  // Right score
                                  Container(
                                    constraints: BoxConstraints(
                                      minWidth: isCompact ? 40 : 60,
                                    ),
                                    child: Text(
                                      rightScore.toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: scoreFontSize,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                        color: isRightTeamMine &&
                                                isWin &&
                                                !isLiveGame
                                            ? const Color(0xFF00FF00)
                                            : isRightTeamMine &&
                                                    isLoss &&
                                                    !isLiveGame
                                                ? const Color(0xFFFF0000)
                                                : const Color(0xFFFFD700),
                                        shadows: [
                                          Shadow(
                                            color: isRightTeamMine &&
                                                    isWin &&
                                                    !isLiveGame
                                                ? const Color(0xFF00FF00)
                                                : isRightTeamMine &&
                                                        isLoss &&
                                                        !isLiveGame
                                                    ? const Color(0xFFFF0000)
                                                    : const Color(0xFFFFD700),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_currentGame!.gameStatus.index >= 9)
                                Padding(
                                  padding:
                                      EdgeInsets.only(top: verticalSpacing),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isCompact ? 10 : 16,
                                        vertical: isCompact ? 3 : 5),
                                    decoration: BoxDecoration(
                                      color: isWin
                                          ? const Color(0xFF00FF00)
                                              .withOpacity(0.2)
                                          : isLoss
                                              ? const Color(0xFFFF0000)
                                                  .withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          isCompact ? 6 : 8),
                                      border: Border.all(
                                        color: isWin
                                            ? const Color(0xFF00FF00)
                                                .withOpacity(0.5)
                                            : isLoss
                                                ? const Color(0xFFFF0000)
                                                    .withOpacity(0.5)
                                                : Colors.grey.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isWin
                                          ? 'WIN'
                                          : isLoss
                                              ? 'LOSS'
                                              : 'TIE',
                                      style: TextStyle(
                                        fontSize: isCompact ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: isWin
                                            ? const Color(0xFF00FF00)
                                            : isLoss
                                                ? const Color(0xFFFF0000)
                                                : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Away team (right)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isCompact ? 6 : 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isRightTeamMine
                                    ? Colors.amber.withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.2),
                                width: isRightTeamMine ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isCompact)
                                  Text(
                                    'AWAY',
                                    style: TextStyle(
                                      fontSize: headerFontSize * 0.7,
                                      color: Colors.amber.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                if (!isCompact)
                                  SizedBox(height: verticalSpacing / 2),
                                if (rightTeam.logoUrl != null &&
                                    rightTeam.logoUrl!.isNotEmpty)
                                  SizedBox(
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: ResponsiveAvatar(
                                      imageUrl: rightTeam.logoUrl,
                                      backgroundColor:
                                          rightTeam.color1.withOpacity(0.2),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: avatarSize,
                                    height: avatarSize,
                                    child: ResponsiveAvatar(
                                      initials: rightTeam.shortName.isNotEmpty
                                          ? rightTeam.shortName[0]
                                          : null,
                                      backgroundColor:
                                          rightTeam.color1.withOpacity(0.2),
                                      fallbackIcon: Icon(
                                        Icons.sports_soccer,
                                        color: rightTeam.color1,
                                        size: avatarSize * 0.6,
                                      ),
                                    ),
                                  ),
                                SizedBox(height: verticalSpacing),
                                Text(
                                  rightTeam.shortName,
                                  style: TextStyle(
                                    fontSize: teamNameFontSize,
                                    fontWeight: isRightTeamMine
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Description if available
                    if (_currentGame!.description != null &&
                        _currentGame!.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: sectionSpacing * 0.75),
                        child: Text(
                          _currentGame!.description!,
                          style: TextStyle(
                            fontSize: descriptionFontSize,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ), // closes InkWell
        ); // closes Card
      },
    );
  }
}
