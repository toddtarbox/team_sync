// Web-specific imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AnchorElement, Blob, Url;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';

/// Card styles for player cards
enum PlayerCardStyle {
  classic,
  modern,
  vintage,
  neon,
}

/// Widget to generate baseball card-style player cards
class PlayerCardGenerator {
  /// Show dialog to generate and share player card
  static Future<void> showPlayerCardDialog(
    BuildContext context, {
    required Team team,
    required Player player,
    String? eventContext, // e.g., "GOAL!" or "HAT TRICK!"
  }) async {
    final isProUser = SubscriptionService.instance.isSubscribed;

    // On mobile, require Pro subscription
    // On web, allow all users (since profile access is already available)
    if (!kIsWeb && !isProUser) {
      // Show Pro feature teaser for non-Pro mobile users
      await showDialog(
        context: context,
        builder: (context) => _PlayerCardProTeaserDialog(
          team: team,
          player: player,
        ),
      );
      return;
    }

    // Show full player card generator for:
    // - Pro users on mobile
    // - All users on web
    await showDialog(
      context: context,
      builder: (context) => _PlayerCardDialog(
        team: team,
        player: player,
        eventContext: eventContext,
      ),
    );
  }
}

/// Pro feature teaser dialog
class _PlayerCardProTeaserDialog extends StatelessWidget {
  final Team team;
  final Player player;

  const _PlayerCardProTeaserDialog({
    Key? key,
    required this.team,
    required this.player,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.stars, color: team.color1),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Player Card Generator',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 64, color: team.color1),
          const SizedBox(height: 16),
          Text(
            'Create professional player cards for ${player.displayName}!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pro features include:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FeatureItem(
                  icon: Icons.photo_camera, text: 'Action photo cards'),
              _FeatureItem(icon: Icons.style, text: 'Multiple card styles'),
              _FeatureItem(icon: Icons.share, text: 'Share to social media'),
              _FeatureItem(
                  icon: Icons.celebration, text: 'Goal celebration posts'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await SubscriptionService.instance.purchaseSubscription();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: team.color1,
            foregroundColor: Colors.white,
          ),
          child: const Text('Upgrade to Pro'),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

/// Main player card dialog
class _PlayerCardDialog extends StatefulWidget {
  final Team team;
  final Player player;
  final String? eventContext;

  const _PlayerCardDialog({
    Key? key,
    required this.team,
    required this.player,
    this.eventContext,
  }) : super(key: key);

  @override
  State<_PlayerCardDialog> createState() => _PlayerCardDialogState();
}

class _PlayerCardDialogState extends State<_PlayerCardDialog> {
  PlayerCardStyle _selectedStyle = PlayerCardStyle.classic;
  final GlobalKey _cardKey = GlobalKey();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.team.color1,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Player Card - ${widget.player.displayName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Style selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Card Style',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PlayerCardStyle.values.map((style) {
                        final isSelected = _selectedStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_getStyleName(style)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedStyle = style);
                              }
                            },
                            selectedColor: widget.team.color1,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Card preview
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _PlayerCardWidget(
                    team: widget.team,
                    player: widget.player,
                    style: _selectedStyle,
                    eventContext: widget.eventContext,
                  ),
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
              child: kIsWeb
                  ?
                  // Web: Only show download button
                  ElevatedButton.icon(
                      onPressed:
                          _isGenerating ? null : () => _captureAndShare(false),
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(_isGenerating ? 'Generating...' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.team.color1,
                        foregroundColor: Colors.white,
                      ),
                    )
                  :
                  // Mobile: Show both share and tweet buttons
                  Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : () => _captureAndShare(false),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.team.color1,
                              side: BorderSide(color: widget.team.color1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : () => _captureAndShare(true),
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send, size: 18),
                            label:
                                Text(_isGenerating ? 'Generating...' : 'Tweet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DA1F2),
                              foregroundColor: Colors.white,
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

  String _getStyleName(PlayerCardStyle style) {
    switch (style) {
      case PlayerCardStyle.classic:
        return 'Classic';
      case PlayerCardStyle.modern:
        return 'Modern';
      case PlayerCardStyle.vintage:
        return 'Vintage';
      case PlayerCardStyle.neon:
        return 'Neon';
    }
  }

  Future<void> _captureAndShare(bool tweet) async {
    setState(() => _isGenerating = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Could not find render boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not convert image to bytes');

      final pngBytes = byteData.buffer.asUint8List();

      setState(() => _isGenerating = false);

      if (tweet) {
        // For tweeting, we need a file (works on all platforms via temp file on mobile, memory on web)
        File? file;

        if (!kIsWeb) {
          // Mobile: Save to temporary file
          final tempDir = await getTemporaryDirectory();
          file = File(
              '${tempDir.path}/player_card_${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(pngBytes);
        } else {
          // Web: Create a temporary file-like object (won't actually save to disk)
          final tempDir = await getTemporaryDirectory();
          file = File(
              '${tempDir.path}/player_card_${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(pngBytes);
        }

        // Show tweet preview dialog
        final shouldTweet = await _showTweetPreview(file);
        if (shouldTweet == true) {
          setState(() => _isGenerating = true);
          await _tweetPlayerCard(file);
          setState(() => _isGenerating = false);

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Text('Tweeted successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Share functionality
        if (kIsWeb) {
          // On web, download the image
          // ignore: avoid_web_libraries_in_flutter
          final blob = html.Blob([pngBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download',
                'player_card_${widget.player.displayName.replaceAll(' ', '_')}.png')
            ..click();
          html.Url.revokeObjectUrl(url);

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Text('Player card downloaded!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Mobile: Save and share via system share sheet
          final tempDir = await getTemporaryDirectory();
          final file = File(
              '${tempDir.path}/player_card_${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(pngBytes);

          await Share.shareXFiles(
            [XFile(file.path)],
            text:
                '${widget.player.displayName} #${widget.player.number} - ${widget.team.shortName}',
          );

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Text('Shared successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<bool?> _showTweetPreview(File imageFile) async {
    // Generate tweet text
    String tweetText = '';
    if (widget.eventContext != null) {
      tweetText =
          '${widget.eventContext} ${widget.player.displayName} #${widget.player.number}';
    } else {
      tweetText =
          '${widget.player.displayName} #${widget.player.number} - ${widget.team.shortName}';
    }

    // Use common tweet preview dialog
    final finalText = await TweetPreviewDialog.show(
      context,
      initialText: tweetText,
      team: widget.team,
      imageFile: imageFile,
      eventContext: widget.eventContext,
    );

    // Return true if user confirmed (finalText is not null), false otherwise
    return finalText != null;
  }

  Future<void> _tweetPlayerCard(File imageFile) async {
    // Check Twitter configuration
    final isConfigured =
        await TwitterService.instance.isConfigured(teamId: widget.team.id);
    if (!isConfigured) {
      final localInit =
          await TwitterService.instance.initializeWithLocalCredentials();
      if (!localInit) {
        throw Exception('Twitter not configured');
      }
    }

    // Generate tweet text
    String tweetText = '';
    if (widget.eventContext != null) {
      tweetText =
          '${widget.eventContext} ${widget.player.displayName} #${widget.player.number}';
    } else {
      tweetText =
          '${widget.player.displayName} #${widget.player.number} - ${widget.team.shortName}';
    }

    // Note: Twitter API v1.1 image upload would go here
    // For now, just send text tweet
    await TwitterService.instance.sendTweet(tweetText);
  }
}

/// Player card widget that gets rendered and captured
class _PlayerCardWidget extends StatelessWidget {
  final Team team;
  final Player player;
  final PlayerCardStyle style;
  final String? eventContext;

  const _PlayerCardWidget({
    Key? key,
    required this.team,
    required this.player,
    required this.style,
    this.eventContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStyleConfig(style);

    return Container(
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.borderColor, width: 3),
        gradient: config.gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with event context
          if (eventContext != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: config.accentColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Center(
                child: Text(
                  eventContext!,
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

          // Action photo
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: config.photoBackgroundColor,
              ),
              child: player.actionPhoto != null
                  ? (player.actionPhoto!.startsWith('http')
                      ? Image.network(
                          player.actionPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPhotoPlaceholder(config);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(player.actionPhoto!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPhotoPlaceholder(config);
                          },
                        ))
                  : player.profileImage != null
                      ? (player.profileImage!.startsWith('http')
                          ? Image.network(
                              player.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPhotoPlaceholder(config);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(player.profileImage!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPhotoPlaceholder(config);
                              },
                            ))
                      : _buildPhotoPlaceholder(config),
            ),
          ),

          // Player info section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: config.infoBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(13)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player number (large)
                  Text(
                    '#${player.number}',
                    style: TextStyle(
                      color: config.accentColor,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Player name
                  Text(
                    player.displayName.toUpperCase(),
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Team name
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: config.accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      team.shortName.toUpperCase(),
                      style: TextStyle(
                        color: config.backgroundColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(_StyleConfig config) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 80,
            color: config.textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No Photo',
            style: TextStyle(
              color: config.textColor.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  _StyleConfig _getStyleConfig(PlayerCardStyle style) {
    switch (style) {
      case PlayerCardStyle.classic:
        return _StyleConfig(
          backgroundColor: Colors.white,
          borderColor: team.color1,
          accentColor: team.color1,
          textColor: Colors.black,
          photoBackgroundColor: Colors.grey[200]!,
          infoBackgroundColor: Colors.white,
        );
      case PlayerCardStyle.modern:
        return _StyleConfig(
          backgroundColor: Colors.grey[900]!,
          borderColor: team.color1,
          accentColor: team.color1,
          textColor: Colors.white,
          photoBackgroundColor: Colors.grey[800]!,
          infoBackgroundColor: Colors.grey[900]!,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        );
      case PlayerCardStyle.vintage:
        return _StyleConfig(
          backgroundColor: const Color(0xFFF5E6D3),
          borderColor: const Color(0xFF8B4513),
          accentColor: const Color(0xFF8B4513),
          textColor: const Color(0xFF3E2723),
          photoBackgroundColor: const Color(0xFFE8D5C4),
          infoBackgroundColor: const Color(0xFFF5E6D3),
        );
      case PlayerCardStyle.neon:
        return _StyleConfig(
          backgroundColor: Colors.black,
          borderColor: team.color1,
          accentColor: team.color1,
          textColor: team.color1,
          photoBackgroundColor: Colors.grey[900]!,
          infoBackgroundColor: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, team.color1.withValues(alpha: 0.2)],
          ),
        );
    }
  }
}

class _StyleConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final Color textColor;
  final Color photoBackgroundColor;
  final Color infoBackgroundColor;
  final Gradient? gradient;

  _StyleConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.textColor,
    required this.photoBackgroundColor,
    required this.infoBackgroundColor,
    this.gradient,
  });
}
