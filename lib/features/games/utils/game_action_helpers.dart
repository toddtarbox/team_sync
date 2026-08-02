import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/features/social_media/services/twitter_service.dart';
import 'package:team_sync/features/social_media/widgets/tweet_preview_dialog.dart';
import 'package:team_sync/features/sports/services/sport_strategy.dart';

class GameActionHelpers {
  /// Opens a dialog to edit the live stream link for a given game.
  /// Calls [onUpdate] if the game is updated so the UI can refresh.
  static Future<void> editLiveLink({
    required BuildContext context,
    required Game? game,
    required Team? team,
    required VoidCallback onUpdate,
  }) async {
    if (team == null || game == null) return;

    String liveLink = game.gameLinks ?? '';
    final hasLiveLink = liveLink.isNotEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Show which game this link is for
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: team.color1.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: team.color1.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(SportStrategy.current.sportIcon,
                            color: team.color1, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            game.displayName(team.id),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(AppLocalizations.of(context)!.setLiveLink,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.liveUrlLabel),
                    controller: TextEditingController(text: liveLink),
                    onChanged: (v) => liveLink = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          // Save to game
                          await DatabaseService.instance.update(
                            'Games',
                            {'gameLinks': liveLink},
                            key: game.id.toString(),
                          );

                          // Update local game object
                          game.gameLinks = liveLink;

                          // Refresh state
                          onUpdate();

                          if (context.mounted) Navigator.pop(context);

                          // After saving, offer to tweet if link is not empty
                          if (liveLink.isNotEmpty && context.mounted) {
                            promptTweetGameDay(
                              context: context,
                              liveLink: liveLink,
                              game: game,
                              team: team,
                            );
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Remove from game
                          await DatabaseService.instance.update(
                            'Games',
                            {'gameLinks': ''},
                            key: game.id.toString(),
                          );

                          // Update local game object
                          game.gameLinks = '';

                          // Refresh state
                          onUpdate();

                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.removeButton),
                      ),
                    ],
                  ),
                  // Show "Tweet Game Day" button if link already exists
                  if (hasLiveLink) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          promptTweetGameDay(
                            context: context,
                            liveLink: liveLink,
                            game: game,
                            team: team,
                          );
                        },
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(loc.tweetGameDay),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DA1F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            );
          },
        );
      },
    );
  }

  /// Initiates game day tweet flow.
  /// Reuses live link logic: prompts to set link if missing, checks game time, then tweets.
  static Future<void> tweetGameDay({
    required BuildContext context,
    required Game? game,
    required Team? team,
    required VoidCallback onUpdate,
  }) async {
    if (team == null || game == null) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.noGameAvailableToTweetAbout),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final liveLink = game.gameLinks ?? '';

    if (liveLink.isEmpty) {
      // Prompt to set live link first
      final shouldSetLink = await showDialog<bool>(
        context: context,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.setLiveStreamLink)),
              ],
            ),
            content: Text(
              'Would you like to add a live stream link for ${game.displayName(team.id)}?\n\n'
              'This helps fans find where to watch the game.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.skip),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.addLink),
              ),
            ],
          );
        },
      );

      if (shouldSetLink == true && context.mounted) {
        // Show live link dialog for this specific game
        await editLiveLink(
          context: context,
          game: game,
          team: team,
          onUpdate: onUpdate,
        );
        // After setting link, the dialog will automatically proceed with tweet
      } else if (shouldSetLink == false && context.mounted) {
        // User chose to skip, proceed without link (will generate generic tweet)
        await promptTweetGameDay(
          context: context,
          liveLink: '',
          game: game,
          team: team,
        );
      }
      // If null (cancelled), do nothing
    } else {
      // Live link exists on this game, proceed with game day tweet
      await promptTweetGameDay(
        context: context,
        liveLink: liveLink,
        game: game,
        team: team,
      );
    }
  }

  /// Prompts for game time if not set, then shows the tweet preview dialog.
  static Future<void> promptTweetGameDay({
    required BuildContext context,
    required String liveLink,
    required Game? game,
    required Team? team,
  }) async {
    if (team == null) return;

    // Check if Twitter is configured
    final isConfigured =
        await TwitterService.instance.isConfigured(teamId: team.id);

    if (!isConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Twitter is not configured. Please set up Twitter credentials in Settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Check if game time is not set (midnight/00:00)
    if (game != null && game.date.hour == 0 && game.date.minute == 0) {
      // Prompt user to set game time first
      final shouldSetTime = await showDialog<bool>(
        context: context,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.setGameTime)),
              ],
            ),
            content: Text(loc.noTimeSetPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.skip),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.setTime),
              ),
            ],
          );
        },
      );

      if (shouldSetTime == true && context.mounted) {
        // Show time picker
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 19, minute: 0), // Default 7:00 PM
          helpText: 'Select game time',
        );

        if (selectedTime != null && context.mounted) {
          // Update game with new time
          final updatedGameDate = DateTime(
            game.date.year,
            game.date.month,
            game.date.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          // Save to database in ISO8601 format (Game.fromMap now handles this)
          try {
            await DatabaseService.instance.update(
              'Games',
              {'date': updatedGameDate.toIso8601String()},
              key: game.id.toString(),
            );

            // Update the game object's date directly
            game.date = updatedGameDate;

            if (context.mounted) {
              final loc = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        loc.gameTimeSet(selectedTime.format(context)),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              final loc = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.errorUpdatingGameTime(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // User cancelled time picker
          return;
        }
      } else if (shouldSetTime == false) {
        // User chose to skip, continue with tweet
      } else {
        // User cancelled dialog
        return;
      }
    }

    // Generate tweet text
    String tweetText = generateGameDayTweet(game, liveLink, team);

    if (context.mounted) {
      // Show preview dialog - it handles initialization, sending, and feedback internally
      await TweetPreviewDialog.show(
        context,
        initialText: tweetText,
        teamId: team.id,
        team: team,
      );
    }
    // Dialog handles all success/error feedback
  }

  /// Generates the tweet text based on game, link, and team.
  static String generateGameDayTweet(Game? game, String liveLink, Team? team) {
    if (team == null) return '';

    final teamName = team.shortName;
    final now = DateTime.now();

    final watchText = liveLink.isNotEmpty
        ? 'Watch LIVE: $liveLink'
        : 'Live streaming link will be shared once the game starts!';

    if (game != null) {
      final gameDate = game.date;
      final isToday = gameDate.year == now.year &&
          gameDate.month == now.month &&
          gameDate.day == now.day;

      final opponent =
          game.displayName(team.id).replaceAll('vs ', '').replaceAll('@ ', '');
      final isHome = game.displayName(team.id).startsWith('vs');
      final location = isHome ? 'home' : 'away';

      // Format time in 12-hour format
      final hour = gameDate.hour == 0
          ? 12
          : (gameDate.hour > 12 ? gameDate.hour - 12 : gameDate.hour);
      final period = gameDate.hour >= 12 ? 'PM' : 'AM';
      final minute = gameDate.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $period';

      if (isToday) {
        return '''🚨 GAME DAY! 🚨

$teamName takes on $opponent $location TODAY at $timeStr!

$watchText

#$teamName #GameDay #Soccer ⚽🔥''';
      } else {
        final month = [
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
        ][gameDate.month - 1];
        final dateStr = '$month ${gameDate.day}';

        return '''🚨 GAME DAY! 🚨

$teamName vs $opponent
📅 $dateStr at $timeStr
🏟️ ${isHome ? 'Home' : 'Away'} game

$watchText

#$teamName #Soccer''';
      }
    } else {
      // No game info, just generic announcement
      return '''🔴 LIVE STREAM AVAILABLE! 🔴

Watch $teamName in action!

$liveLink

#$teamName #LiveSoccer ⚽''';
    }
  }
}
