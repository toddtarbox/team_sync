import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';

/// Visual styles for lineup display
enum LineupStyle {
  classic,
  darkMode,
  minimal,
  retro,
  neon,
  elegant,
}

/// Widget to generate and capture a starting lineup/formation image
class LineupGenerator {
  /// Show dialog to configure and generate lineup
  static Future<void> showLineupDialog(
    BuildContext context, {
    required Team team,
    required List<Player> players,
    Game? game,
  }) async {
    // Block web users - this is a mobile-only feature
    if (kIsWeb) {
      final loc = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.lineupGeneratorMobileOnly),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final isProUser = SubscriptionService.instance.isSubscribed;

    if (!isProUser) {
      // Show Pro feature teaser for non-Pro users
      await showDialog(
        context: context,
        builder: (context) => _LineupProTeaserDialog(
          team: team,
          players: players,
        ),
      );
      return;
    }

    // Show full lineup generator for Pro users
    await showDialog(
      context: context,
      builder: (context) => LineupDialog(
        team: team,
        players: players,
        game: game,
      ),
    );
  }
}

/// Pro feature teaser dialog for lineup generator
class _LineupProTeaserDialog extends StatelessWidget {
  final Team team;
  final List<Player> players;

  const _LineupProTeaserDialog({
    Key? key,
    required this.team,
    required this.players,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get first 11 players or all available for preview
    final previewPlayers = players.take(11).toList();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Preview lineup image with blur/overlay
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred preview of lineup
                  if (previewPlayers.length >= 11)
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.3),
                        BlendMode.darken,
                      ),
                      child: Opacity(
                        opacity: 0.6,
                        child: LineupWidget(
                          team: team,
                          players: previewPlayers,
                          formation: '4-4-2',
                          matchDetails: 'Your Team vs Opponent',
                          matchDateTime: DateTime.now(),
                          motivationalMessage: 'Let\'s bring home the victory!',
                          style: LineupStyle.classic,
                        ),
                      ),
                    )
                  else
                    // Generic preview if not enough players
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            team.color1,
                            team.color2,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.sports_soccer,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  // Overlay with Pro badge and info
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          // Pro badge
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Pro Feature',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Generate professional lineup images with multiple styles',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Feature list
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFeatureItem(
                                    '✓ 6 visual styles (Classic, Dark, Neon, etc.)'),
                                const SizedBox(height: 8),
                                _buildFeatureItem(
                                    '✓ Custom match details & motivational messages'),
                                const SizedBox(height: 8),
                                _buildFeatureItem('✓ Player profile images'),
                                const SizedBox(height: 8),
                                _buildFeatureItem(
                                    '✓ Multiple formations (4-4-2, 4-3-3, etc.)'),
                                const SizedBox(height: 8),
                                _buildFeatureItem(
                                    '✓ Perfect for social media sharing'),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await SubscriptionService.instance
                            .purchaseSubscription();
                      },
                      icon: const Icon(Icons.upgrade, size: 24),
                      label: const Text(
                        'Upgrade to Pro',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.amber,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text.substring(2), // Remove the checkmark from text
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dialog for configuring and generating lineup
class LineupDialog extends StatefulWidget {
  final Team team;
  final List<Player> players;
  final Game? game;

  const LineupDialog({
    Key? key,
    required this.team,
    required this.players,
    this.game,
  }) : super(key: key);

  @override
  State<LineupDialog> createState() => _LineupDialogState();
}

class _LineupDialogState extends State<LineupDialog> {
  String _formation = '4-3-3';
  List<Player?> _selectedPlayers = List.filled(11, null);
  bool _isGenerating = false;
  String _motivationalMessage = '';
  DateTime? _matchDateTime;
  String _matchDetails = '';
  LineupStyle _selectedStyle = LineupStyle.classic;

  final _messageController = TextEditingController();
  final _detailsController = TextEditingController();

  final List<String> _formations = [
    '4-4-2',
    '4-3-3',
    '3-5-2',
    '4-2-3-1',
    '4-5-1',
    '3-4-3',
  ];

  // Motivational messages for lineup images (100 total)
  static const List<String> _motivationalMessages = [
    // Victory & Winning (20 messages)
    'Let\'s bring home the victory! ⚽',
    'Victory awaits! 🏆',
    'Time to conquer! 👑',
    'Winners never quit! 💪',
    'Destined for greatness! ⭐',
    'Born to win! 🔥',
    'Victory is our tradition! 🏅',
    'Winning starts now! ⚡',
    'Champions rise today! 🌟',
    'Glory is within reach! 🎯',
    'We came to dominate! 💯',
    'This is our time to shine! ✨',
    'Victory tastes sweet! 🍯',
    'We own this game! 👊',
    'Unstoppable force activated! 🚀',
    'Victory mode: ON! ⚡',
    'Champions on the pitch! 🏆',
    'Game. Set. Victory! 🎾',
    'Winning is our language! 🗣️',
    'Victory is the only option! ✅',

    // Teamwork & Unity (20 messages)
    'Together we are unstoppable! 💪',
    'One team, one dream! 🏆',
    'United we stand! 🤝',
    'Stronger together! 💪',
    'We fight as one! ⚔️',
    'Brotherhood on the field! 👊',
    'Team first, always! 🤝',
    'Unity is our strength! 💪',
    'All for one, one for all! 🎯',
    'Together we achieve more! 🌟',
    'Squad goals activated! 🔥',
    'Family on three! 👨‍👩‍👧‍👦',
    'No weak links here! ⛓️',
    'Connected by victory! 🔗',
    'Team chemistry at 100%! ⚗️',
    'One heartbeat, one team! ❤️',
    'United in purpose! 🎯',
    'Strength in numbers! 💯',
    'Together we conquer! 🏔️',
    'The power of WE! 🤝',

    // Heart & Passion (20 messages)
    'Play with heart, win with pride! ❤️',
    'Leave it all on the field! 🔥',
    'Heart over everything! ❤️',
    'Play like you mean it! 💪',
    'Passion fuels greatness! 🔥',
    'Give it everything! 💯',
    'Heart of a champion! 💖',
    'Blood, sweat, and glory! 💧',
    'Play with soul! 🎵',
    'Desire drives us! 🔥',
    'Fire in our hearts! 🔥',
    'Relentless passion! 💪',
    'Love the game, dominate! ❤️',
    'Heart stronger than fear! 💪',
    'Pure determination! 🎯',
    'Play with purpose! 🔥',
    'Hungry for success! 🍽️',
    'Passion meets precision! 🎯',
    'Fearless hearts unite! ❤️',
    'Intensity maximized! 🔥',

    // Determination & Grit (20 messages)
    'Champions are made today! ⭐',
    'No excuses, just results! 💯',
    'Earned not given! 🔥',
    'We don\'t back down! 💪',
    'Refuse to lose! ⚡',
    'Grit over talent! 💎',
    'Grind mode activated! ⚙️',
    'No surrender, no retreat! ⚔️',
    'Tough times don\'t last! 💪',
    'Persistence pays off! 💰',
    'Never give up! 🚫',
    'Rise to the challenge! 📈',
    'Adversity breeds champions! 🏆',
    'Push beyond limits! 🚀',
    'Warrior mentality! ⚔️',
    'Built different! 💪',
    'Unbreakable spirit! 🛡️',
    'No quit in our DNA! 🧬',
    'Resilience is key! 🔑',
    'Pressure makes diamonds! 💎',

    // Excellence & Pride (20 messages)
    'Every game is our game! ⚡',
    'Make every moment count! ⏱️',
    'This is our moment! 🌟',
    'Excellence is our standard! 📊',
    'Greatness on display! 🎭',
    'Playing at the highest level! 🔝',
    'Perfect execution time! ✓',
    'Elite performance mode! 👑',
    'Precision and power! ⚡',
    'Quality over quantity! 💎',
    'First class performance! 🎖️',
    'Representing with pride! 🦅',
    'Honor the badge! 🛡️',
    'Pride in every touch! ⚽',
    'Legacy in the making! 📜',
    'Setting the standard! 📏',
    'World class display! 🌍',
    'Nothing but excellence! ⭐',
    'Masterclass incoming! 🎓',
    'Peak performance ready! ⛰️',

    // Mindset & Attitude (20 messages)
    'Believe in the process! 🎯',
    'Play hard, stay humble! 🙏',
    'Win or learn, never lose! 📈',
    'Success starts with attitude! 😤',
    'Champions mindset activated! 🧠',
    'Game faces on! 😤',
    'Confidence is key! 🔑',
    'Focus and execute! 🎯',
    'Mental toughness wins! 🧠',
    'Positive vibes only! ✨',
    'Stay hungry, stay humble! 🍽️',
    'Mindset over matter! 🧠',
    'Think win, play win! 💭',
    'Laser focused! 🔦',
    'Locked in and ready! 🔒',
    'All gas, no brakes! ⛽',
    'Business mode activated! 💼',
    'Eyes on the prize! 👀',
    'Focused on victory! 🎯',
    'No distractions allowed! 🚫',
  ];

  @override
  void initState() {
    super.initState();

    // Auto-generate a motivational message
    _motivationalMessage = _motivationalMessages[
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length];
    _messageController.text = _motivationalMessage;

    // Pre-fill with game info if available
    if (widget.game != null) {
      final gameDate = widget.game!.date;

      // If game time is midnight (00:00), treat it as "time not set" and default to 7:00 PM
      if (gameDate.hour == 0 && gameDate.minute == 0) {
        _matchDateTime = DateTime(
          gameDate.year,
          gameDate.month,
          gameDate.day,
          19, // 7:00 PM
          0,
        );
      } else {
        _matchDateTime = gameDate;
      }

      _detailsController.text = widget.game!.displayName(widget.team.id);
      _matchDetails = _detailsController.text;
    }
    // Load saved lineup
    _loadSavedLineup();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  /// Load the last saved lineup for this team and season
  Future<void> _loadSavedLineup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lineup_${widget.team.id}';
      final savedData = prefs.getString(key);

      if (savedData != null) {
        final data = jsonDecode(savedData) as Map<String, dynamic>;

        bool hasChanges = false;

        // Restore formation
        final savedFormation = data['formation'] as String?;
        if (savedFormation != null && _formations.contains(savedFormation)) {
          setState(() {
            _formation = savedFormation;
          });
          hasChanges = true;
        }

        // Restore style
        final savedStyleIndex = data['styleIndex'] as int?;
        if (savedStyleIndex != null &&
            savedStyleIndex >= 0 &&
            savedStyleIndex < LineupStyle.values.length) {
          setState(() {
            _selectedStyle = LineupStyle.values[savedStyleIndex];
          });
          hasChanges = true;
        }

        // Restore player selections
        final savedPlayerIds = data['playerIds'] as List<dynamic>?;
        if (savedPlayerIds != null && savedPlayerIds.length == 11) {
          final restoredPlayers = List<Player?>.filled(11, null);
          int restoredCount = 0;

          for (int i = 0; i < 11; i++) {
            final playerId = savedPlayerIds[i] as int?;
            if (playerId != null) {
              // Find player in the current player list
              try {
                final player = widget.players.firstWhere(
                  (p) => p.id == playerId,
                );
                // Only add if this player isn't already in the list
                if (!restoredPlayers.contains(player)) {
                  restoredPlayers[i] = player;
                  restoredCount++;
                }
              } catch (e) {
                // Player not found in current list, skip
              }
            }
          }

          if (restoredCount > 0) {
            setState(() {
              _selectedPlayers = restoredPlayers;
            });
            hasChanges = true;
          }
        }

        // Show notification if lineup was loaded
        if (hasChanges && mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final loc = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.restore, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(loc.previousLineupRestored),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: widget.team.color1,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      // Silently fail - not critical if loading fails
      debugPrint('Failed to load saved lineup: $e');
    }
  }

  /// Save the current lineup configuration
  Future<void> _saveLineup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'lineup_${widget.team.id}';

      final playerIds = _selectedPlayers.map((p) => p?.id).toList();

      final data = {
        'formation': _formation,
        'styleIndex': _selectedStyle.index,
        'playerIds': playerIds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to save lineup: $e');
    }
  }

  /// Generate a new random motivational message
  void _generateNewMotivationalMessage() {
    // Use a more random approach - combine timestamp with a random component
    final random = (DateTime.now().microsecondsSinceEpoch +
            DateTime.now().millisecondsSinceEpoch.hashCode) %
        _motivationalMessages.length;

    final newMessage = _motivationalMessages[random];

    setState(() {
      _motivationalMessage = newMessage;
      _messageController.text = newMessage;
    });
  }

  /// Format time in 12-hour format with AM/PM
  String _formatTime(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 850),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: widget.team.color1,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Generate Lineup',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formation section
                    Text(
                      'Formation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _formation,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _formations.map((formation) {
                        return DropdownMenuItem(
                          value: formation,
                          child: Text(formation),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _formation = value;
                            _selectedPlayers = List.filled(11, null);
                          });
                          _saveLineup();
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Match details section
                    Text(
                      'Match Details (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., vs Chelsea FC, Home Game',
                        prefixIcon: const Icon(Icons.stadium),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _matchDetails = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Date and Time pickers (separate)
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _matchDateTime ?? DateTime.now(),
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null && mounted) {
                                setState(() {
                                  if (_matchDateTime != null) {
                                    // Preserve existing time
                                    _matchDateTime = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      _matchDateTime!.hour,
                                      _matchDateTime!.minute,
                                    );
                                  } else {
                                    // Set date with default time (7:00 PM)
                                    _matchDateTime = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      19,
                                      0,
                                    );
                                  }
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon:
                                    Icon(Icons.calendar_today, size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              child: Text(
                                _matchDateTime != null
                                    ? '${_matchDateTime!.day}/${_matchDateTime!.month}/${_matchDateTime!.year}'
                                    : 'Match Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _matchDateTime != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time picker
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _matchDateTime != null
                                    ? TimeOfDay.fromDateTime(_matchDateTime!)
                                    : const TimeOfDay(
                                        hour: 19,
                                        minute: 0), // Default to 7:00 PM
                              );
                              if (time != null && mounted) {
                                setState(() {
                                  if (_matchDateTime != null) {
                                    // Preserve existing date
                                    _matchDateTime = DateTime(
                                      _matchDateTime!.year,
                                      _matchDateTime!.month,
                                      _matchDateTime!.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  } else {
                                    // Set time with today's date
                                    final now = DateTime.now();
                                    _matchDateTime = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  }
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time, size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              child: Text(
                                _matchDateTime != null
                                    ? _formatTime(_matchDateTime!)
                                    : 'Time',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _matchDateTime != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Motivational message section with regenerate button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Motivational Message (Optional)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 22),
                          tooltip: 'Generate new message',
                          onPressed: _generateNewMotivationalMessage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., Let\'s bring home the victory! ⚽',
                        prefixIcon: const Icon(Icons.format_quote),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      maxLength: 60,
                      onChanged: (value) {
                        setState(() {
                          _motivationalMessage = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Players section
                    Text(
                      'Select Players (Starting 11)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerSelection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isGenerating ||
                          _selectedPlayers.where((p) => p != null).length < 11
                      ? null
                      : _generateAndShare,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(loc.generateImage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelection() {
    final loc = AppLocalizations.of(context)!;
    final positions = _getPositions();

    return Column(
      children: List.generate(
        positions.length,
        (index) {
          final position = positions[index];
          final selectedPlayer = _selectedPlayers[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    position,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Player?>(
                    initialValue: selectedPlayer,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      hintText: loc.selectPlayer,
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    items: [
                      DropdownMenuItem<Player?>(
                        value: null,
                        child: Text(loc.selectPlayer),
                      ),
                      ...widget.players.map((player) {
                        final isAlreadySelected =
                            _selectedPlayers.contains(player) &&
                                selectedPlayer != player;
                        return DropdownMenuItem<Player?>(
                          value: player,
                          enabled: !isAlreadySelected,
                          child: Text(
                            '${player.number} - ${player.displayName}',
                            style: TextStyle(
                              color: isAlreadySelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (player) {
                      setState(() {
                        _selectedPlayers[index] = player;
                      });
                      _saveLineup();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _getPositions() {
    switch (_formation) {
      case '4-4-2':
        return [
          'GK',
          'LB',
          'CB',
          'CB',
          'RB',
          'LM',
          'CM',
          'CM',
          'RM',
          'ST',
          'ST'
        ];
      case '4-3-3':
        return [
          'GK',
          'LB',
          'CB',
          'CB',
          'RB',
          'CM',
          'CM',
          'CM',
          'LW',
          'ST',
          'RW'
        ];
      case '3-5-2':
        return [
          'GK',
          'CB',
          'CB',
          'CB',
          'LWB',
          'CM',
          'CM',
          'CM',
          'RWB',
          'ST',
          'ST'
        ];
      case '4-2-3-1':
        return [
          'GK',
          'LB',
          'CB',
          'CB',
          'RB',
          'CDM',
          'CDM',
          'CAM',
          'LW',
          'RW',
          'ST'
        ];
      case '4-5-1':
        return [
          'GK',
          'LB',
          'CB',
          'CB',
          'RB',
          'LM',
          'CM',
          'CM',
          'CM',
          'RM',
          'ST'
        ];
      case '3-4-3':
        return [
          'GK',
          'CB',
          'CB',
          'CB',
          'LM',
          'CM',
          'CM',
          'RM',
          'LW',
          'ST',
          'RW'
        ];
      default:
        return List.filled(11, 'P');
    }
  }

  Future<void> _generateAndShare() async {
    setState(() => _isGenerating = true);

    try {
      final nonNullPlayers = _selectedPlayers.whereType<Player>().toList();

      if (nonNullPlayers.length < 11) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.pleaseSelectAll11Players),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // Generate the lineup widget
      final lineupWidget = RepaintBoundary(
        child: LineupWidget(
          team: widget.team,
          players: nonNullPlayers,
          formation: _formation,
          game: widget.game,
          matchDetails: _matchDetails.isNotEmpty ? _matchDetails : null,
          matchDateTime: _matchDateTime,
          motivationalMessage:
              _motivationalMessage.isNotEmpty ? _motivationalMessage : null,
          style: _selectedStyle,
        ),
      );

      // Show a preview dialog with share options
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _LineupPreviewDialog(
            lineupWidget: lineupWidget,
            team: widget.team,
            formation: _formation,
            style: _selectedStyle,
          ),
        );

        // Close the configuration dialog after sharing
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating lineup: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

/// Preview dialog for generated lineup with share options
class _LineupPreviewDialog extends StatefulWidget {
  final Widget lineupWidget;
  final Team team;
  final String formation;
  final LineupStyle style;

  const _LineupPreviewDialog({
    Key? key,
    required this.lineupWidget,
    required this.team,
    required this.formation,
    required this.style,
  }) : super(key: key);

  @override
  State<_LineupPreviewDialog> createState() => _LineupPreviewDialogState();
}

class _LineupPreviewDialogState extends State<_LineupPreviewDialog> {
  bool _isSharing = false;
  final GlobalKey _repaintKey = GlobalKey();
  late LineupStyle _currentStyle;
  late Widget _currentLineupWidget;
  bool _isTwitterConfigured = false;

  @override
  void initState() {
    super.initState();
    _currentStyle = widget.style;
    _updateLineupWidget();
    _checkTwitterConfiguration();
  }

  Future<void> _checkTwitterConfiguration() async {
    if (kIsWeb) {
      setState(() => _isTwitterConfigured = false);
      return;
    }

    // First try team credentials (from Firebase/settings)
    bool isConfigured = await TwitterService.instance
        .initializeWithTeamCredentials(widget.team.id);

    // Fallback to local credentials if team credentials not found
    if (!isConfigured) {
      isConfigured =
          await TwitterService.instance.initializeWithLocalCredentials();
    }

    if (mounted) {
      setState(() => _isTwitterConfigured = isConfigured);
    }
  }

  void _updateLineupWidget() {
    // Extract the LineupWidget from the RepaintBoundary
    final repaintBoundary = widget.lineupWidget as RepaintBoundary;
    final originalLineup = repaintBoundary.child as LineupWidget;

    // Create new LineupWidget with current style
    _currentLineupWidget = RepaintBoundary(
      key: _repaintKey,
      child: LineupWidget(
        team: originalLineup.team,
        players: originalLineup.players,
        formation: originalLineup.formation,
        game: originalLineup.game,
        matchDetails: originalLineup.matchDetails,
        matchDateTime: originalLineup.matchDateTime,
        motivationalMessage: originalLineup.motivationalMessage,
        style: _currentStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Minimal header - with style selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.team.color1.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(
                    color: widget.team.color1.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: widget.team.color1,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lineup Generated • ${widget.formation}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _isSharing
                            ? null
                            : () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Style selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: LineupStyle.values.map((style) {
                        final isSelected = _currentStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              _getStyleDisplayName(style),
                              style: const TextStyle(fontSize: 12),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected && _currentStyle != style) {
                                setState(() {
                                  _currentStyle = style;
                                  _updateLineupWidget();
                                });
                              }
                            },
                            selectedColor:
                                widget.team.color1.withValues(alpha: 0.3),
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Large preview - takes almost entire screen
            Expanded(
              child: Container(
                color: Colors.black87,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 2.0,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 1080,
                        height: 1920,
                        child: _currentLineupWidget,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Action buttons - Share, Twitter (if configured), and Close
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Share button (primary action)
                  ElevatedButton.icon(
                    onPressed: _isSharing ? null : _captureAndShare,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share, size: 18),
                    label: Text(
                      _isSharing ? 'Preparing...' : 'Share Image',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.team.color1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Secondary action buttons row
                  Row(
                    children: [
                      // Twitter button (conditional)
                      if (_isTwitterConfigured)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSharing ? null : _shareToTwitter,
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text(
                              'Twitter',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1DA1F2),
                              side: const BorderSide(color: Color(0xFF1DA1F2)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (_isTwitterConfigured) const SizedBox(width: 8),
                      // Close button
                      Expanded(
                        child: TextButton(
                          onPressed: _isSharing
                              ? null
                              : () => Navigator.of(context).pop(),
                          child:
                              Text(loc.close, style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleDisplayName(LineupStyle style) {
    switch (style) {
      case LineupStyle.classic:
        return 'Classic';
      case LineupStyle.darkMode:
        return 'Dark Mode';
      case LineupStyle.minimal:
        return 'Minimal';
      case LineupStyle.retro:
        return 'Retro';
      case LineupStyle.neon:
        return 'Neon';
      case LineupStyle.elegant:
        return 'Elegant';
    }
  }

  Future<void> _captureAndShare() async {
    setState(() => _isSharing = true);

    try {
      // Find the RepaintBoundary
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find render boundary');
      }

      // Capture the image at high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Could not convert image to bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final filename =
          'lineup_${widget.team.shortName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      // Close the dialog first
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.team.fullName} Starting XI - ${widget.formation}',
      );

      // Close dialog and show success
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(loc.lineupSharedSuccessfully),
              ],
            ),
            backgroundColor: widget.team.color1,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _shareToTwitter() async {
    setState(() => _isSharing = true);

    try {
      // Find the RepaintBoundary
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Could not find render boundary');
      }

      // Capture the image at high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Could not convert image to bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temporary file for Twitter
      final tempDir = await getTemporaryDirectory();
      final filename =
          'lineup_${widget.team.shortName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      // Generate initial tweet text
      final tweetText = _generateTweetText();

      // Show tweet preview dialog - it handles initialization, sending, and feedback internally
      if (!mounted) return;

      final success = await TweetPreviewDialog.show(
        context,
        initialText: tweetText,
        teamId: widget.team.id,
        team: widget.team,
        imageFile: file,
        eventContext: 'Starting XI',
      );

      // If tweet was sent successfully, close the lineup preview
      if (success && mounted) {
        Navigator.of(context).pop();
      }
      // If user cancelled or failed, lineup preview stays open
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to Twitter: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String _generateTweetText() {
    final teamName = widget.team.shortName;
    final formationText = widget.formation;

    return '''🔥 Starting XI Alert! 🔥

$teamName takes the field in $formationText formation!

#$teamName #MatchDay #StartingXI #Soccer ⚽''';
  }
}

/// Widget that displays the lineup visually (for capturing)
class LineupWidget extends StatelessWidget {
  final Team team;
  final List<Player> players;
  final String formation;
  final Game? game;
  final String? matchDetails;
  final DateTime? matchDateTime;
  final String? motivationalMessage;
  final LineupStyle style;

  const LineupWidget({
    Key? key,
    required this.team,
    required this.players,
    required this.formation,
    this.game,
    this.matchDetails,
    this.matchDateTime,
    this.motivationalMessage,
    this.style = LineupStyle.classic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final styleConfig = _getStyleConfig();

    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        gradient: styleConfig.backgroundGradient,
        color: styleConfig.backgroundColor,
      ),
      child: Stack(
        children: [
          // Decorative pattern overlay for some styles
          if (styleConfig.patternOverlay != null)
            Positioned.fill(
              child: styleConfig.patternOverlay!,
            ),
          // Header
          Positioned(
            top: 40,
            left: 40,
            right: 40,
            child: Column(
              children: [
                if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                  Container(
                    decoration: styleConfig.logoDecoration,
                    padding: const EdgeInsets.all(8),
                    child: Image.network(
                      team.logoUrl!,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  team.fullName,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: styleConfig.headerFontWeight,
                    color: styleConfig.primaryTextColor,
                    fontFamily: styleConfig.fontFamily,
                    shadows: styleConfig.textShadows,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Starting XI - $formation',
                  style: TextStyle(
                    fontSize: 32,
                    color: styleConfig.secondaryTextColor,
                    fontFamily: styleConfig.fontFamily,
                    shadows: styleConfig.textShadows,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Match details from parameter or game
                if (matchDetails != null && matchDetails!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: styleConfig.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: styleConfig.accentColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      matchDetails!,
                      style: TextStyle(
                        fontSize: 26,
                        color: styleConfig.primaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: styleConfig.fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else if (game != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    game!.displayName(team.id),
                    style: TextStyle(
                      fontSize: 28,
                      color: styleConfig.secondaryTextColor,
                      fontFamily: styleConfig.fontFamily,
                      shadows: styleConfig.textShadows,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                // Match date and time
                if (matchDateTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color:
                            styleConfig.primaryTextColor.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(matchDateTime!)} at ${_formatTime(matchDateTime!)}',
                        style: TextStyle(
                          fontSize: 22,
                          color: styleConfig.primaryTextColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: styleConfig.fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
                // Motivational message
                if (motivationalMessage != null &&
                    motivationalMessage!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: styleConfig.accentColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: styleConfig.cardShadows,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: styleConfig.primaryTextColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            motivationalMessage!,
                            style: TextStyle(
                              fontSize: 24,
                              color: styleConfig.primaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              fontFamily: styleConfig.fontFamily,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.format_quote,
                          color: styleConfig.primaryTextColor,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Players positioned on field
          Positioned(
            top: 280,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFormation(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormation() {
    final positions = _getPlayerPositions();

    return Stack(
      children: List.generate(
        players.length > 11 ? 11 : players.length,
        (index) {
          if (index >= players.length) return const SizedBox();

          final player = players[index];
          final position = positions[index];

          return Positioned(
            left: position.dx,
            top: position.dy,
            child: _buildPlayerCard(player),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(Player player) {
    final hasProfileImage =
        player.profileImage != null && player.profileImage!.isNotEmpty;

    return Column(
      children: [
        Container(
          width: 120, // Increased from 80
          height: 120, // Increased from 80
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border:
                Border.all(color: team.color1, width: 5), // Increased from 4
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10, // Increased from 6
                offset: const Offset(0, 4), // Increased from 0, 3
              ),
            ],
          ),
          child: ClipOval(
            child: hasProfileImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      // Player profile image
                      Image.network(
                        player.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to number if image fails to load
                          return Container(
                            color: Colors.white,
                            child: Center(
                              child: Text(
                                player.number.toString(),
                                style: TextStyle(
                                  fontSize: 48, // Increased from 32
                                  fontWeight: FontWeight.bold,
                                  color: team.color1,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Jersey number badge overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4), // Increased from 2
                          decoration: BoxDecoration(
                            color: team.color1.withValues(alpha: 0.95),
                          ),
                          child: Text(
                            player.number.toString(),
                            style: const TextStyle(
                              fontSize: 22, // Increased from 16
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      player.number.toString(),
                      style: TextStyle(
                        fontSize: 48, // Increased from 32
                        fontWeight: FontWeight.bold,
                        color: team.color1,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12), // Increased from 8
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8), // Increased from 12, 6
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Increased from 16
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.3), // Increased from 0.2
                blurRadius: 6, // Increased from 4
                offset: const Offset(0, 3), // Increased from 0, 2
              ),
            ],
          ),
          child: Text(
            player.lastName.toUpperCase(),
            style: TextStyle(
              fontSize: 20, // Increased from 16
              fontWeight: FontWeight.bold,
              color: team.color1,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  List<Offset> _getPlayerPositions() {
    // Return positions based on formation
    // Total canvas: 1080x1920
    // Top 280px reserved for header
    // Available field area: 1080x1640
    // Center horizontally: width * 0.5 - 60 (accounting for 120px player card width)
    const width = 1080.0;
    const height = 1640.0;
    const centerX = width * 0.5 - 60; // Center accounting for player card width

    switch (formation) {
      case '4-4-2':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.12, height * 0.70), // LB
          Offset(width * 0.33, height * 0.70), // CB
          Offset(width * 0.57, height * 0.70), // CB
          Offset(width * 0.78, height * 0.70), // RB
          Offset(width * 0.12, height * 0.45), // LM
          Offset(width * 0.33, height * 0.45), // CM
          Offset(width * 0.57, height * 0.45), // CM
          Offset(width * 0.78, height * 0.45), // RM
          Offset(width * 0.33, height * 0.18), // ST
          Offset(width * 0.57, height * 0.18), // ST
        ];
      case '4-3-3':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.12, height * 0.70), // LB
          Offset(width * 0.33, height * 0.70), // CB
          Offset(width * 0.57, height * 0.70), // CB
          Offset(width * 0.78, height * 0.70), // RB
          Offset(width * 0.28, height * 0.45), // CM
          Offset(centerX, height * 0.45), // CM - centered
          Offset(width * 0.62, height * 0.45), // CM
          Offset(width * 0.12, height * 0.18), // LW
          Offset(centerX, height * 0.18), // ST - centered
          Offset(width * 0.78, height * 0.18), // RW
        ];
      case '3-5-2':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.25, height * 0.70), // CB
          Offset(centerX, height * 0.70), // CB - centered
          Offset(width * 0.65, height * 0.70), // CB
          Offset(width * 0.08, height * 0.45), // LWB
          Offset(width * 0.28, height * 0.45), // CM
          Offset(centerX, height * 0.45), // CM - centered
          Offset(width * 0.62, height * 0.45), // CM
          Offset(width * 0.82, height * 0.45), // RWB
          Offset(width * 0.33, height * 0.18), // ST
          Offset(width * 0.57, height * 0.18), // ST
        ];
      case '4-2-3-1':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.12, height * 0.70), // LB
          Offset(width * 0.33, height * 0.70), // CB
          Offset(width * 0.57, height * 0.70), // CB
          Offset(width * 0.78, height * 0.70), // RB
          Offset(width * 0.33, height * 0.55), // CDM
          Offset(width * 0.57, height * 0.55), // CDM
          Offset(centerX, height * 0.35), // CAM - centered
          Offset(width * 0.12, height * 0.25), // LW
          Offset(width * 0.78, height * 0.25), // RW
          Offset(centerX, height * 0.10), // ST - centered
        ];
      case '4-5-1':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.12, height * 0.70), // LB
          Offset(width * 0.33, height * 0.70), // CB
          Offset(width * 0.57, height * 0.70), // CB
          Offset(width * 0.78, height * 0.70), // RB
          Offset(width * 0.08, height * 0.45), // LM
          Offset(width * 0.28, height * 0.45), // CM
          Offset(centerX, height * 0.45), // CM - centered
          Offset(width * 0.62, height * 0.45), // CM
          Offset(width * 0.82, height * 0.45), // RM
          Offset(centerX, height * 0.18), // ST - centered
        ];
      case '3-4-3':
        return [
          Offset(centerX, height * 0.88), // GK - centered
          Offset(width * 0.25, height * 0.70), // CB
          Offset(centerX, height * 0.70), // CB - centered
          Offset(width * 0.65, height * 0.70), // CB
          Offset(width * 0.12, height * 0.45), // LM
          Offset(width * 0.33, height * 0.45), // CM
          Offset(width * 0.57, height * 0.45), // CM
          Offset(width * 0.78, height * 0.45), // RM
          Offset(width * 0.12, height * 0.18), // LW
          Offset(centerX, height * 0.18), // ST - centered
          Offset(width * 0.78, height * 0.18), // RW
        ];
      default:
        // Default evenly spaced vertical line
        return List.generate(
            11, (i) => Offset(centerX, height * 0.08 * (i + 1) + 50));
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  _StyleConfig _getStyleConfig() {
    switch (style) {
      case LineupStyle.classic:
        return _StyleConfig(
          backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [team.color1, team.color2],
          ),
          primaryTextColor: Colors.white,
          secondaryTextColor: Colors.white70,
          accentColor: Colors.white,
          fieldLineColor: Colors.white.withValues(alpha: 0.15),
          fieldLineWidth: 3,
          showField: true,
          headerFontWeight: FontWeight.bold,
          textShadows: [
            const Shadow(
              offset: Offset(2, 2),
              blurRadius: 4,
              color: Color.fromARGB(128, 0, 0, 0),
            ),
          ],
          cardShadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case LineupStyle.darkMode:
        return _StyleConfig(
          backgroundColor: const Color(0xFF121212),
          backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a1a),
              const Color(0xFF0a0a0a),
            ],
          ),
          primaryTextColor: Colors.white,
          secondaryTextColor: const Color(0xFFBBBBBB),
          accentColor: team.color1,
          fieldLineColor: team.color1.withValues(alpha: 0.3),
          fieldLineWidth: 2,
          showField: true,
          headerFontWeight: FontWeight.w600,
          textShadows: [
            Shadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: team.color1.withValues(alpha: 0.5),
            ),
          ],
          cardShadows: [
            BoxShadow(
              color: team.color1.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case LineupStyle.minimal:
        return _StyleConfig(
          backgroundColor: Colors.white,
          primaryTextColor: const Color(0xFF333333),
          secondaryTextColor: const Color(0xFF666666),
          accentColor: team.color1,
          fieldLineColor: const Color(0xFFE0E0E0),
          fieldLineWidth: 1,
          showField: true,
          headerFontWeight: FontWeight.w300,
          fontFamily: 'Helvetica',
          textShadows: [],
          cardShadows: [
            const BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        );

      case LineupStyle.retro:
        return _StyleConfig(
          backgroundColor: const Color(0xFFFFF8E7),
          primaryTextColor: const Color(0xFF4A2C2A),
          secondaryTextColor: const Color(0xFF8B6F47),
          accentColor: const Color(0xFFD4A574),
          fieldLineColor: const Color(0xFFB8956A).withValues(alpha: 0.4),
          fieldLineWidth: 4,
          showField: true,
          headerFontWeight: FontWeight.w900,
          fontFamily: 'Courier',
          textShadows: [
            const Shadow(
              offset: Offset(3, 3),
              blurRadius: 0,
              color: Color(0xFFD4A574),
            ),
          ],
          cardShadows: [
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
          patternOverlay: CustomPaint(
            painter: _RetroPatternPainter(),
          ),
        );

      case LineupStyle.neon:
        return _StyleConfig(
          backgroundColor: const Color(0xFF0D0221),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0221),
              Color(0xFF1A0B3F),
            ],
          ),
          primaryTextColor: const Color(0xFFFF006E),
          secondaryTextColor: const Color(0xFF8338EC),
          accentColor: const Color(0xFFFF006E),
          fieldLineColor: const Color(0xFF3A86FF).withValues(alpha: 0.5),
          fieldLineWidth: 2,
          showField: true,
          headerFontWeight: FontWeight.bold,
          textShadows: [
            const Shadow(
              offset: Offset(0, 0),
              blurRadius: 20,
              color: Color(0xFFFF006E),
            ),
            const Shadow(
              offset: Offset(0, 0),
              blurRadius: 40,
              color: Color(0xFFFF006E),
            ),
          ],
          cardShadows: [
            const BoxShadow(
              color: Color(0xFFFF006E),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
          ],
        );

      case LineupStyle.elegant:
        return _StyleConfig(
          backgroundColor: const Color(0xFFF5F5F5),
          backgroundGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFAFAFA),
              const Color(0xFFEEEEEE),
            ],
          ),
          primaryTextColor: const Color(0xFF2C3E50),
          secondaryTextColor: const Color(0xFF7F8C8D),
          accentColor: const Color(0xFFBDC3C7),
          fieldLineColor: const Color(0xFFBDC3C7).withValues(alpha: 0.3),
          fieldLineWidth: 1.5,
          showField: true,
          headerFontWeight: FontWeight.w200,
          fontFamily: 'Georgia',
          logoDecoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              const BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          textShadows: [],
          cardShadows: [
            const BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        );
    }
  }
}

class _StyleConfig {
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color fieldLineColor;
  final double fieldLineWidth;
  final bool showField;
  final FontWeight headerFontWeight;
  final String? fontFamily;
  final BoxDecoration? logoDecoration;
  final List<Shadow> textShadows;
  final List<BoxShadow> cardShadows;
  final Widget? patternOverlay;

  _StyleConfig({
    this.backgroundColor,
    this.backgroundGradient,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.fieldLineColor,
    required this.fieldLineWidth,
    required this.showField,
    required this.headerFontWeight,
    this.fontFamily,
    this.logoDecoration,
    required this.textShadows,
    required this.cardShadows,
    this.patternOverlay,
  });
}

class _RetroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A574).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw diagonal stripes
    const stripeWidth = 40.0;
    for (double i = -size.height;
        i < size.width + size.height;
        i += stripeWidth * 2) {
      canvas.drawRect(
        Rect.fromPoints(
          Offset(i, 0),
          Offset(i + stripeWidth, size.height),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for soccer field background
class SoccerFieldPainter extends CustomPainter {
  final Color fieldColor;
  final double strokeWidth;

  SoccerFieldPainter({
    this.fieldColor = const Color(0x26FFFFFF),
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fieldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fillPaint = Paint()
      ..color = fieldColor.withValues(alpha: fieldColor.a * 0.5)
      ..style = PaintingStyle.fill;

    // Field dimensions
    final fieldWidth = size.width;
    final fieldHeight = size.height;
    final margin = 40.0;

    // Outer boundary
    canvas.drawRect(
      Rect.fromLTWH(
          margin, margin, fieldWidth - margin * 2, fieldHeight - margin * 2),
      paint,
    );

    // Center line (horizontal)
    canvas.drawLine(
      Offset(margin, fieldHeight / 2),
      Offset(fieldWidth - margin, fieldHeight / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(fieldWidth / 2, fieldHeight / 2),
      120,
      paint,
    );

    // Center spot
    canvas.drawCircle(
      Offset(fieldWidth / 2, fieldHeight / 2),
      8,
      fillPaint,
    );

    // Penalty areas (18-yard boxes)
    final penaltyBoxWidth = fieldWidth * 0.5;
    final penaltyBoxHeight = 200.0;

    // Top penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (fieldWidth - penaltyBoxWidth) / 2,
        margin,
        penaltyBoxWidth,
        penaltyBoxHeight,
      ),
      paint,
    );

    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
        (fieldWidth - penaltyBoxWidth) / 2,
        fieldHeight - margin - penaltyBoxHeight,
        penaltyBoxWidth,
        penaltyBoxHeight,
      ),
      paint,
    );

    // Goal areas (6-yard boxes)
    final goalBoxWidth = fieldWidth * 0.25;
    final goalBoxHeight = 80.0;

    // Top goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (fieldWidth - goalBoxWidth) / 2,
        margin,
        goalBoxWidth,
        goalBoxHeight,
      ),
      paint,
    );

    // Bottom goal area
    canvas.drawRect(
      Rect.fromLTWH(
        (fieldWidth - goalBoxWidth) / 2,
        fieldHeight - margin - goalBoxHeight,
        goalBoxWidth,
        goalBoxHeight,
      ),
      paint,
    );

    // Penalty spots
    final penaltySpotDistance = 140.0;

    // Top penalty spot
    canvas.drawCircle(
      Offset(fieldWidth / 2, margin + penaltySpotDistance),
      8,
      fillPaint,
    );

    // Bottom penalty spot
    canvas.drawCircle(
      Offset(fieldWidth / 2, fieldHeight - margin - penaltySpotDistance),
      8,
      fillPaint,
    );

    // Penalty arcs (D-shaped curves)
    final penaltyArcRadius = 120.0;

    // Top penalty arc
    final topArcRect = Rect.fromCircle(
      center: Offset(fieldWidth / 2, margin + penaltySpotDistance),
      radius: penaltyArcRadius,
    );
    canvas.drawArc(
      topArcRect,
      3.14159, // π (180 degrees)
      3.14159, // π (180 degrees sweep)
      false,
      paint,
    );

    // Bottom penalty arc
    final bottomArcRect = Rect.fromCircle(
      center:
          Offset(fieldWidth / 2, fieldHeight - margin - penaltySpotDistance),
      radius: penaltyArcRadius,
    );
    canvas.drawArc(
      bottomArcRect,
      0, // 0 degrees
      3.14159, // π (180 degrees sweep)
      false,
      paint,
    );

    // Corner arcs
    final cornerRadius = 30.0;

    // Top-left corner
    canvas.drawArc(
      Rect.fromLTWH(margin - cornerRadius, margin - cornerRadius,
          cornerRadius * 2, cornerRadius * 2),
      0,
      1.5708, // π/2 (90 degrees)
      false,
      paint,
    );

    // Top-right corner
    canvas.drawArc(
      Rect.fromLTWH(fieldWidth - margin - cornerRadius, margin - cornerRadius,
          cornerRadius * 2, cornerRadius * 2),
      1.5708, // π/2
      1.5708, // π/2 (90 degrees)
      false,
      paint,
    );

    // Bottom-left corner
    canvas.drawArc(
      Rect.fromLTWH(margin - cornerRadius, fieldHeight - margin - cornerRadius,
          cornerRadius * 2, cornerRadius * 2),
      4.71239, // 3π/2
      1.5708, // π/2 (90 degrees)
      false,
      paint,
    );

    // Bottom-right corner
    canvas.drawArc(
      Rect.fromLTWH(
          fieldWidth - margin - cornerRadius,
          fieldHeight - margin - cornerRadius,
          cornerRadius * 2,
          cornerRadius * 2),
      3.14159, // π
      1.5708, // π/2 (90 degrees)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
