import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/features/social_media/widgets/tweet_preview_dialog.dart';

/// A reusable dialog for composing and sending adhoc tweets.
///
/// This widget provides:
/// - Text input with character counter (280 character limit)
/// - Visual feedback for character limit
/// - Preview before sending
/// - Send/Cancel buttons
/// - Automatic Twitter API initialization check
class AdhocTweetDialog extends StatefulWidget {
  final int? teamId;
  final Team? team;

  const AdhocTweetDialog({super.key, this.teamId, this.team});

  /// Show the adhoc tweet dialog and handle the tweet sending.
  /// Returns true if tweet was sent successfully, false otherwise.
  static Future<bool> show(BuildContext context,
      {int? teamId, Team? team}) async {
    // Load team if we have teamId but no team object
    Team? loadedTeam = team;
    if (loadedTeam == null && teamId != null) {
      try {
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );
        if (results.isNotEmpty) {
          loadedTeam = Team.fromMap(results.first);
        }
      } catch (e) {
        debugPrint('Error loading team: $e');
      }
    }

    // Show the compose dialog first
    if (!context.mounted) return false;

    final composedTweet = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AdhocTweetDialog(
        teamId: teamId,
        team: loadedTeam,
      ),
    );

    // If user composed a tweet, show preview
    if (composedTweet != null && composedTweet.isNotEmpty) {
      if (!context.mounted) return false;

      // Show preview dialog - it handles initialization and sending internally
      return await TweetPreviewDialog.show(
        context,
        initialText: composedTweet,
        teamId: teamId,
        team: loadedTeam,
      );
    }

    return false;
  }

  @override
  State<AdhocTweetDialog> createState() => _AdhocTweetDialogState();
}

class _AdhocTweetDialogState extends State<AdhocTweetDialog> {
  final _textController = TextEditingController();
  String _tweetText = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.composeTweet),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'What\'s happening?',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            maxLength: 280,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _tweetText = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            '${_tweetText.length}/280 characters',
            style: TextStyle(
              color: _tweetText.length > 280 ? Colors.red : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: _tweetText.isEmpty || _tweetText.length > 280
              ? null
              : () {
                  Navigator.pop(context, _tweetText);
                },
          child: Text(loc.preview),
        ),
      ],
    );
  }
}
