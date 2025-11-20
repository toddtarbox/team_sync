import 'package:flutter/material.dart';
import 'package:team_sync/services/twitter_service.dart';

/// A reusable dialog for composing and sending adhoc tweets.
///
/// This widget provides:
/// - Text input with character counter (280 character limit)
/// - Visual feedback for character limit
/// - Send/Cancel buttons
/// - Automatic Twitter API initialization check
class AdhocTweetDialog extends StatefulWidget {
  final int? teamId;

  const AdhocTweetDialog({super.key, this.teamId});

  /// Show the adhoc tweet dialog and handle the tweet sending.
  /// Returns true if tweet was sent successfully, false otherwise.
  static Future<bool> show(BuildContext context, {int? teamId}) async {
    final twitterService = TwitterService.instance;

    // Check if Twitter is configured
    final isConfigured = await twitterService.isConfigured(teamId: teamId);

    if (!isConfigured) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Twitter is not configured. Please configure Twitter in Settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Initialize Twitter with appropriate credentials
    bool initialized = false;
    if (teamId != null) {
      initialized = await twitterService.initializeWithTeamCredentials(teamId);
    } else {
      initialized = await twitterService.initializeWithLocalCredentials();
    }

    if (!initialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to initialize Twitter. Please check your credentials.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }

    // Show the dialog
    if (!context.mounted) return false;

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AdhocTweetDialog(teamId: teamId),
    );

    // If user confirmed, send the tweet
    if (result != null && result.isNotEmpty) {
      final success = await twitterService.sendTweet(result);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tweet sent successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send tweet. Please try again.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      return success;
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
      title: const Text('Send Tweet'),
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
          child: const Text('Send Tweet'),
        ),
      ],
    );
  }
}
