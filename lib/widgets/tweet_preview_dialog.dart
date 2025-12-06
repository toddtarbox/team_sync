import 'dart:io';

import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/twitter_service.dart';

/// Common tweet preview dialog that can be used across the app
/// for all tweet sending flows (adhoc, game day, player cards, etc.)
class TweetPreviewDialog {
  /// Show a tweet preview dialog before sending
  /// Returns true if tweet was sent successfully, false if cancelled or failed
  static Future<bool> show(
    BuildContext context, {
    required String initialText,
    int? teamId,
    Team? team,
    File? imageFile,
    String? eventContext,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _TweetPreviewDialogWidget(
        initialText: initialText,
        teamId: teamId,
        team: team,
        imageFile: imageFile,
        eventContext: eventContext,
      ),
    );
    return result ?? false;
  }
}

class _TweetPreviewDialogWidget extends StatefulWidget {
  final String initialText;
  final int? teamId;
  final Team? team;
  final File? imageFile;
  final String? eventContext;

  const _TweetPreviewDialogWidget({
    required this.initialText,
    this.teamId,
    this.team,
    this.imageFile,
    this.eventContext,
  });

  @override
  State<_TweetPreviewDialogWidget> createState() =>
      _TweetPreviewDialogWidgetState();
}

class _TweetPreviewDialogWidgetState extends State<_TweetPreviewDialogWidget> {
  late TextEditingController _textController;
  String? _twitterHandle;
  bool _loadingHandle = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _loadTwitterHandle();
  }

  Future<void> _loadTwitterHandle() async {
    try {
      final handle = await TwitterService.instance
          .getTwitterHandle(teamId: widget.teamId ?? widget.team?.id);
      if (mounted) {
        setState(() {
          _twitterHandle = handle;
          _loadingHandle = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _twitterHandle = null;
          _loadingHandle = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color get _teamColor => widget.team?.color1 ?? const Color(0xFF1DA1F2);

  String get _displayName {
    if (_twitterHandle != null) return _twitterHandle!;
    if (widget.team != null) return widget.team!.shortName;
    return 'Team';
  }

  String get _displayHandle {
    if (_twitterHandle != null) return '@$_twitterHandle';
    if (widget.team != null) {
      return '@${widget.team!.shortName.replaceAll(' ', '').toLowerCase()}';
    }
    return '@team';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final characterCount = _textController.text.length;
    final isOverLimit = characterCount > 280;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: widget.imageFile != null ? 700 : 600,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1DA1F2), // Twitter blue
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preview Tweet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            // Preview content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mock Twitter post preview
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Twitter profile header
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _teamColor,
                                radius: 20,
                                child: widget.team?.logoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.team!.logoUrl!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.sports_soccer,
                                              color: Colors.white,
                                              size: 20,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.sports_soccer,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _loadingHandle
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 15,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 14,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            _displayHandle,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Tweet text (editable)
                          TextField(
                            controller: _textController,
                            maxLines: null,
                            maxLength: 280,
                            decoration: const InputDecoration(
                              hintText: 'What\'s happening?',
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            style: const TextStyle(fontSize: 15),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),

                          // Character count
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '$characterCount/280',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOverLimit
                                        ? Colors.red
                                        : characterCount > 260
                                            ? Colors.orange
                                            : Colors.grey[600],
                                    fontWeight: isOverLimit
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Image preview if provided
                          if (widget.imageFile != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                widget.imageFile!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Mock Twitter actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _TwitterAction(
                                  icon: Icons.chat_bubble_outline, count: '0'),
                              _TwitterAction(icon: Icons.repeat, count: '0'),
                              _TwitterAction(
                                  icon: Icons.favorite_border, count: '0'),
                              _TwitterAction(
                                  icon: Icons.share_outlined, count: ''),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can edit the tweet text above before sending.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Event context badge (for goal tweets, etc.)
                    if (widget.eventContext != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sports_soccer,
                                size: 16, color: Colors.orange[900]),
                            const SizedBox(width: 6),
                            Text(
                              widget.eventContext!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(loc.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ||
                              _textController.text.isEmpty ||
                              isOverLimit
                          ? null
                          : () => _sendTweet(),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(_isSending ? 'Sending...' : loc.sendTweet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
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

  Future<void> _sendTweet() async {
    final loc = AppLocalizations.of(context)!;

    setState(() => _isSending = true);

    try {
      // Ensure Twitter is initialized
      final initialized = await TwitterService.instance.ensureInitialized(
        teamId: widget.teamId ?? widget.team?.id,
      );

      if (!initialized) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Twitter is not configured. Please configure Twitter in Settings.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop(false);
        }
        return;
      }

      // Send tweet with image if available
      final success = await TwitterService.instance.sendTweetWithImage(
        _textController.text,
        imageFile: widget.imageFile,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.tweetSentSuccessfully)),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.failedToSendTweet),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.failedToSendTweet}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

/// Mock Twitter action button widget
class _TwitterAction extends StatelessWidget {
  final IconData icon;
  final String count;

  const _TwitterAction({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
