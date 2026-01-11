import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';

import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/sport_strategy.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';

import 'package:team_sync/widgets/responsive_avatar.dart';

/// Widget to generate newspaper-style match result cards for sharing
class MatchResultCard {
  /// Show dialog to generate and share match result card
  static Future<void> showMatchResultDialog(
    BuildContext context, {
    required Season season,
    required Game game,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => _MatchResultDialog(
        season: season,
        game: game,
      ),
    );
  }
}

/// Dialog for match result card generation
class _MatchResultDialog extends StatefulWidget {
  final Season season;
  final Game game;

  const _MatchResultDialog({
    required this.season,
    required this.game,
  });

  @override
  State<_MatchResultDialog> createState() => _MatchResultDialogState();
}

class _MatchResultDialogState extends State<_MatchResultDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header - fixed at top
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.newspaper,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Match Report',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable preview - both horizontal and vertical scrolling
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _MatchResultCardWidget(
                      season: widget.season,
                      game: widget.game,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Actions - fixed at bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _tweetCard(),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Tweet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DA1F2), // Twitter blue
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isGenerating ? null : () => _shareCard(),
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: Text(loc.share),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCard() async {
    setState(() => _isGenerating = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not find render boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not convert image to bytes');

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/match_result_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      final opponent = widget.game.isHomeTeam(widget.season.teamId)
          ? widget.game.awayTeam.shortName
          : widget.game.homeTeam.shortName;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$opponent - Match Result',
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating card: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _tweetCard() async {
    setState(() => _isGenerating = true);

    try {
      // Generate the image
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not find render boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not convert image to bytes');

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/match_result_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      // Generate tweet text
      final isHomeTeam = widget.game.isHomeTeam(widget.season.teamId);
      final teamScore =
          isHomeTeam ? widget.game.homeTeamScore : widget.game.awayTeamScore;
      final opponentScore =
          isHomeTeam ? widget.game.awayTeamScore : widget.game.homeTeamScore;
      final opponentName = isHomeTeam
          ? widget.game.awayTeam.shortName
          : widget.game.homeTeam.shortName;

      final result = teamScore > opponentScore
          ? 'W'
          : (teamScore < opponentScore ? 'L' : 'T');

      // Generate web link to game
      final databaseId = DatabaseService.instance.publicShareId ?? '';
      final baseUrl = SportStrategy.current.webUrl;
      final gameUrl =
          '$baseUrl/team/$databaseId/season/${widget.season.id}/games/${widget.game.id}';

      final tweetText =
          '${widget.season.team.shortName} $result $teamScore-$opponentScore vs $opponentName\n\n$gameUrl\n\n#${widget.season.team.shortName.replaceAll(' ', '')}';

      setState(() => _isGenerating = false);

      // Show tweet preview dialog with image
      final success = await TweetPreviewDialog.show(
        context,
        initialText: tweetText,
        team: widget.season.team,
        teamId: widget.season.teamId,
        imageFile: file,
        eventContext: 'Match Report',
      );

      if (success && mounted) {
        // User confirmed and tweet was sent successfully - close dialog
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating card: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

/// The actual match result card widget
class _MatchResultCardWidget extends StatefulWidget {
  final Season season;
  final Game game;

  const _MatchResultCardWidget({
    required this.season,
    required this.game,
  });

  @override
  State<_MatchResultCardWidget> createState() => _MatchResultCardWidgetState();
}

class _MatchResultCardWidgetState extends State<_MatchResultCardWidget> {
  Map<String, Map<Player, int>>? _playerStats;
  Map<String, int>? _teamTotals;
  Map<String, int>? _opponentTotals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      await widget.game.loadGameEvents();
      final stats = await widget.game.getStats(widget.season.teamId);

      final playerStats = <String, Map<Player, int>>{};
      final teamTotals = <String, int>{};
      final opponentTotals = <String, int>{};

      for (final category in SportStrategy.current.leaderCategories) {
        playerStats[category] = await stats.getStatPlayers(category);

        // Calculate team total
        int teamTotal = 0;
        for (final stat in playerStats[category]!.entries) {
          teamTotal += stat.value;
        }

        // Count corners separately for team
        if (category == 'corners') {
          for (final event in widget.game.allGameEvents) {
            if (event.eventType == 'Corner' &&
                event.team.id == widget.season.teamId) {
              teamTotal++;
            }
          }
        }

        teamTotals[category] = teamTotal;

        // Calculate opponent total from game events
        int opponentTotal = 0;
        for (final event in widget.game.allGameEvents) {
          // Special handling for saves - opponent saves are team shots on goal
          if (category == 'saves') {
            if (event.team.id == widget.season.teamId &&
                event.eventType == 'Shot' &&
                event.eventData == 1) {
              opponentTotal++;
            }
            continue;
          }

          // For other stats, skip team events
          if (event.team.id == widget.season.teamId) continue;

          switch (category) {
            case 'goals':
              if (event.eventType == 'Shot' && event.eventData == 0) {
                opponentTotal++;
              }
              break;
            case 'assists':
              if (event.eventType == 'Assist') opponentTotal++;
              break;
            case 'shots':
              if (event.eventType == 'Shot') opponentTotal++;
              break;
            case 'shotsOnGoal':
              if (event.eventType == 'Shot' &&
                  (event.eventData == 0 || event.eventData == 1)) {
                opponentTotal++;
              }
              break;
            case 'corners':
              if (event.eventType == 'Corner') opponentTotal++;
              break;
            case 'fouls':
              if (event.eventType == 'Foul') opponentTotal++;
              break;
            case 'yellows':
              if (event.eventType == 'Card' && event.eventData == 0) {
                opponentTotal++;
              }
              break;
            case 'reds':
              if (event.eventType == 'Card' && event.eventData == 2) {
                opponentTotal++;
              }
              break;
            case 'secondYellowReds':
              if (event.eventType == 'Card' && event.eventData == 1) {
                opponentTotal++;
              }
              break;
            default:
              break;
          }
        }

        opponentTotals[category] = opponentTotal;
      }

      if (mounted) {
        setState(() {
          _playerStats = playerStats;
          _teamTotals = teamTotals;
          _opponentTotals = opponentTotals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading match stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: 800,
        height: 800,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final teamColor = widget.season.team.color1;

    // Explicitly determine "My Team" vs "Opponent"
    final userIsHome = widget.game.isHomeTeam(widget.season.teamId);

    // Score logic
    final userScore =
        userIsHome ? widget.game.homeTeamScore : widget.game.awayTeamScore;
    final opponentScore =
        userIsHome ? widget.game.awayTeamScore : widget.game.homeTeamScore;

    // Name logic
    final userName = widget.season.team.fullName;
    final opponentName = userIsHome
        ? widget.game.awayTeam.shortName
        : widget.game.homeTeam.shortName;

    // Logo logic - prioritize Game object's team references as they match home/away context
    final userLogo = userIsHome
        ? widget.game.homeTeam.logoUrl
        : widget.game.awayTeam.logoUrl;
    final opponentLogo = userIsHome
        ? widget.game.awayTeam.logoUrl
        : widget.game.homeTeam.logoUrl;

    return Container(
      width: 800,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: teamColor,
              border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 3)),
            ),
            child: Column(
              children: [
                Text(
                  'MATCH REPORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(widget.game.date),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left Column: MY TEAM
                Expanded(
                  child: Column(
                    children: [
                      // My Team Logo
                      if (userLogo != null && userLogo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: ResponsiveAvatar(
                              imageUrl: userLogo,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      Text(
                        userName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userScore.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // VS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                // Right Column: OPPONENT
                Expanded(
                  child: Column(
                    children: [
                      // Opponent Logo
                      if (opponentLogo != null && opponentLogo.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: ResponsiveAvatar(
                              imageUrl: opponentLogo,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      Text(
                        opponentName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            opponentScore.toString(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Grid
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('MATCH STATISTICS'),
                const SizedBox(height: 16),
                _buildStatRow('Shots', _teamTotals!['shots']!,
                    _opponentTotals!['shots']!),
                _buildStatRow('Shots on Goal', _teamTotals!['shotsOnGoal']!,
                    _opponentTotals!['shotsOnGoal']!),
                _buildStatRow('Saves', _teamTotals!['saves']!,
                    _opponentTotals!['saves']!),
                _buildStatRow('Corners', _teamTotals!['corners']!,
                    _opponentTotals!['corners']!),
                _buildStatRow('Fouls', _teamTotals!['fouls']!,
                    _opponentTotals!['fouls']!),
                _buildStatRow('Yellow Cards', _teamTotals!['yellows']!,
                    _opponentTotals!['yellows']!),
                _buildStatRow(
                    'Red Cards',
                    _teamTotals!['reds']! + _teamTotals!['secondYellowReds']!,
                    _opponentTotals!['reds']! +
                        _opponentTotals!['secondYellowReds']!),
              ],
            ),
          ),

          // Goal Scorers
          if (_playerStats!['goals']!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('GOAL SCORERS'),
                  const SizedBox(height: 12),
                  ..._buildPlayerList('goals'),
                ],
              ),
            ),
          ],

          // Assists
          if (_playerStats!['assists']!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('ASSISTS'),
                  const SizedBox(height: 12),
                  ..._buildPlayerList('assists'),
                ],
              ),
            ),
          ],

          // Saves
          if (_playerStats!['saves']!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('SAVES'),
                  const SizedBox(height: 12),
                  ..._buildPlayerList('saves'),
                ],
              ),
            ),
          ],

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border:
                  Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
            ),
            child: Text(
              widget.season.team.fullName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 2)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int teamValue, int opponentValue) {
    final total = teamValue + opponentValue;
    final teamPercentage = total > 0 ? teamValue / total : 0.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                teamValue.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                opponentValue.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (teamPercentage * 100).round(),
                  child: Container(
                    height: 6,
                    color: widget.season.team.color1,
                  ),
                ),
                Expanded(
                  flex: ((1 - teamPercentage) * 100).round(),
                  child: Container(
                    height: 6,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerList(String category) {
    final players = _playerStats![category]!;
    final sortedPlayers = players.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedPlayers.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.season.team.color1,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#${entry.key.number}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.key.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (entry.value > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '×${entry.value}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
