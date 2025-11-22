import 'package:flutter/material.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';

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

  const AdhocTweetDialog({super.key, this.teamId});

  /// Show the adhoc tweet dialog and handle the tweet sending.
  /// Returns true if tweet was sent successfully, false otherwise.
  static Future<bool> show(BuildContext context, {int? teamId}) async {
    final twitterService = TwitterService.instance;

    // Initialize Twitter with appropriate credentials
    // Try team credentials first, then fall back to local
    bool initialized = false;
    if (teamId != null) {
      initialized = await twitterService.initializeWithTeamCredentials(teamId);
      if (!initialized) {
        // Fallback to local credentials
        initialized = await twitterService.initializeWithLocalCredentials();
      }
    } else {
      initialized = await twitterService.initializeWithLocalCredentials();
    }

    // If still not initialized, check if credentials exist at all
    if (!initialized) {
      final isConfigured = await twitterService.isConfigured(teamId: teamId);

      if (!isConfigured) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Twitter is not configured. Please configure Twitter in Settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      } else {
        // Credentials exist but initialization failed
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to initialize Twitter. Please check your credentials.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }

    // Show the compose dialog first
    if (!context.mounted) return false;

    final composedTweet = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AdhocTweetDialog(teamId: teamId),
    );

    // If user composed a tweet, show preview
    if (composedTweet != null && composedTweet.isNotEmpty) {
      if (!context.mounted) return false;

      // Show preview dialog using common component
      final finalTweetText = await TweetPreviewDialog.show(
        context,
        initialText: composedTweet,
        teamId: teamId,
      );

      // If user confirmed in preview, send the tweet
      if (finalTweetText != null && finalTweetText.isNotEmpty) {
        final success = await twitterService.sendTweet(finalTweetText);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tweet sent successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send tweet. Please try again.'),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        return success;
      }
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
    return AlertDialog(
      title: const Text('Compose Tweet'),
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
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _tweetText.isEmpty || _tweetText.length > 280
              ? null
              : () {
                  Navigator.pop(context, _tweetText);
                },
          child: const Text('Preview'),
        ),
      ],
    );
  }
}
