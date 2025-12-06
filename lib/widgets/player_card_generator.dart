// Web-specific imports
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_award.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';

// Conditional import for web
import 'player_card_web_download.dart'
    if (dart.library.io) 'player_card_web_download_stub.dart';

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
    final loc = AppLocalizations.of(context)!;
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
          child: Text(loc.maybeLater),
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
          child: Text(loc.upgradeToPro),
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

class _PlayerCardDialogState extends State<_PlayerCardDialog>
    with SingleTickerProviderStateMixin {
  PlayerCardStyle _selectedStyle = PlayerCardStyle.classic;
  final GlobalKey _cardKey = GlobalKey();
  bool _isGenerating = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showingBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showingBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _showingBack = !_showingBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Flip button with high contrast for dark mode
                        Container(
                          decoration: BoxDecoration(
                            color: widget.team.color1,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.team.color1.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: _flipCard,
                            icon: Icon(
                              _showingBack
                                  ? Icons.flip_to_front
                                  : Icons.flip_to_back,
                              color: Colors.white,
                              size: 24,
                            ),
                            label: Text(
                              _showingBack ? 'Show Front' : 'Show Stats',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Animated flip card
                        AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle =
                                _flipAnimation.value * 3.14159; // π radians
                            final transform = Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // perspective
                              ..rotateY(angle);

                            return Transform(
                              transform: transform,
                              alignment: Alignment.center,
                              child: angle < 3.14159 / 2
                                  ? RepaintBoundary(
                                      key: _cardKey,
                                      child: _PlayerCardWidget(
                                        team: widget.team,
                                        player: widget.player,
                                        style: _selectedStyle,
                                        eventContext: widget.eventContext,
                                      ),
                                    )
                                  : Transform(
                                      transform: Matrix4.identity()
                                        ..rotateY(3.14159),
                                      alignment: Alignment.center,
                                      child: RepaintBoundary(
                                        key: _cardKey,
                                        child: _PlayerCardBackWidget(
                                          team: widget.team,
                                          player: widget.player,
                                          style: _selectedStyle,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
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
                      label: Text(_isGenerating
                          ? 'Generating...'
                          : _showingBack
                              ? 'Download Stats'
                              : 'Download Card'),
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
                          child: ElevatedButton.icon(
                            onPressed: _isGenerating
                                ? null
                                : () => _captureAndShare(false),
                            icon: const Icon(Icons.share, size: 18),
                            label: Text(
                                _showingBack ? 'Share Stats' : 'Share Card'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.team.color1,
                              foregroundColor: Colors.white,
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
                            label: Text(_isGenerating
                                ? 'Generating...'
                                : _showingBack
                                    ? 'Tweet Stats'
                                    : 'Tweet Card'),
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
            final loc = AppLocalizations.of(context)!;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(loc.tweetedSuccessfully),
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
          // On web, download the image using helper function
          final filename = _showingBack
              ? 'player_card_stats_${widget.player.displayName.replaceAll(' ', '_')}.png'
              : 'player_card_${widget.player.displayName.replaceAll(' ', '_')}.png';

          downloadFile(pngBytes, filename);

          if (mounted) {
            final loc = AppLocalizations.of(context)!;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(_showingBack
                        ? 'Player stats downloaded!'
                        : 'Player card downloaded!'),
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
            final loc = AppLocalizations.of(context)!;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(loc.sharedSuccessfully),
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

    // Standard baseball card size: 2.5" x 3.5" at 300 DPI = 750px x 1050px
    return Container(
      width: 750,
      height: 1050,
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
              padding: const EdgeInsets.symmetric(vertical: 24),
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
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
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
              padding: const EdgeInsets.all(32),
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
                      fontSize: 110,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Player name
                  Text(
                    player.displayName.toUpperCase(),
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // Team name
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: config.accentColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      team.fullName.toUpperCase(),
                      style: TextStyle(
                        color: config.backgroundColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            config.photoBackgroundColor,
            config.photoBackgroundColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.accentColor.withValues(alpha: 0.1),
              ),
            ),
            // Soccer player in action icon
            Icon(
              Icons.sports_soccer,
              size: 240,
              color: config.accentColor.withValues(alpha: 0.3),
            ),
          ],
        ),
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

/// Player card back widget showing stats
class _PlayerCardBackWidget extends StatefulWidget {
  final Team team;
  final Player player;
  final PlayerCardStyle style;

  const _PlayerCardBackWidget({
    Key? key,
    required this.team,
    required this.player,
    required this.style,
  }) : super(key: key);

  @override
  State<_PlayerCardBackWidget> createState() => _PlayerCardBackWidgetState();
}

class _PlayerCardBackWidgetState extends State<_PlayerCardBackWidget> {
  int _goals = 0;
  int _assists = 0;
  int _saves = 0;
  List<PlayerAward> _awards = [];
  bool _isLoading = true;

  bool get hasStats => _goals > 0 || _assists > 0 || _saves > 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadAwards();
  }

  Future<void> _loadAwards() async {
    try {
      final awards = await PlayerAward.listFromPlayerId(widget.player.id);
      if (mounted) {
        setState(() {
          _awards = awards
              .take(5)
              .toList(); // Show max 5 awards (compact format fits more)
        });
      }
    } catch (e) {
      debugPrint('Error loading player awards: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      // Query all events for this player
      final events = await DatabaseService.instance.query(
        'Events',
        orderByChild: 'playerId',
        equalTo: widget.player.id,
      );

      // Calculate stats
      int goals = 0;
      int assists = 0;
      int saves = 0;
      Set<int> gameIds = {};

      for (var event in events) {
        final eventType = event['eventType'];
        final gameId = event['gameId'];

        // Count goals (Shot or PenaltyKick with result = goal)
        if ((eventType == 'Shot' || eventType == 'PenaltyKick') &&
            event['eventData'] == 0) {
          // 0 = ShotResult.goal
          goals++;
        }

        // Count assists
        if (eventType == 'Assist') {
          assists++;
        }

        // Count saves
        if (eventType == 'Save') {
          saves++;
        }

        // Track unique games
        if (gameId != null) {
          gameIds.add(gameId);
        }
      }

      if (mounted) {
        setState(() {
          _goals = goals;
          _assists = assists;
          _saves = saves;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading player stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStyleConfig(widget.style);

    // Standard baseball card size: 2.5" x 3.5" at 300 DPI = 750px x 1050px
    // Fixed height to match front card
    return Container(
      width: 750,
      height: 1050,
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: config.accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Center(
              child: Text(
                'CAREER STATS',
                style: TextStyle(
                  color: config.backgroundColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),

          // Player info
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                // Player number circle
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.accentColor,
                  ),
                  child: Center(
                    child: Text(
                      '#${widget.player.number}',
                      style: TextStyle(
                        color: config.backgroundColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Player name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.player.displayName.toUpperCase(),
                        style: TextStyle(
                          color: config.textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.team.fullName.toUpperCase(),
                        style: TextStyle(
                          color: config.textColor.withValues(alpha: 0.7),
                          fontSize: 22,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 2),

          // Stats and content section - use Expanded with scrollable content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: config.accentColor,
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats section
                          if (hasStats) ...[
                            if (_goals > 0)
                              _StatRow(
                                label: 'GOALS',
                                value: _goals.toString(),
                                icon: Icons.sports_soccer,
                                config: config,
                              ),
                            if (_assists > 0)
                              _StatRow(
                                label: 'ASSISTS',
                                value: _assists.toString(),
                                icon: Icons.people,
                                config: config,
                              ),
                            if (_saves > 0)
                              _StatRow(
                                label: 'SAVES',
                                value: _saves.toString(),
                                icon: Icons.back_hand,
                                config: config,
                              ),
                          ],

                          // Awards section - render as list for image capture
                          if (_awards.isNotEmpty) ...[
                            if (hasStats)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color:
                                      config.textColor.withValues(alpha: 0.3),
                                  thickness: 2,
                                ),
                              ),
                            Text(
                              'AWARDS',
                              style: TextStyle(
                                color: config.accentColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Render awards as list (max 5 compact awards fit on card)
                            ..._awards
                                .map((award) => _buildAwardCard(award, config)),
                          ],

                          // QR code section - always show
                          if (hasStats || _awards.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: config.textColor.withValues(alpha: 0.3),
                                thickness: 2,
                              ),
                            ),
                          ],
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'SCAN FOR PROFILE',
                                  style: TextStyle(
                                    color: config.accentColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: config.accentColor
                                          .withValues(alpha: 0.3),
                                      width: 3,
                                    ),
                                  ),
                                  child: QrImageView(
                                    data: _getPlayerWebUrl(),
                                    version: QrVersions.auto,
                                    size: 130,
                                    backgroundColor: Colors.white,
                                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Show message if no stats and no awards
                          if (!hasStats && _awards.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 40),
                                child: Text(
                                  'No stats or awards yet',
                                  style: TextStyle(
                                    color:
                                        config.textColor.withValues(alpha: 0.5),
                                    fontSize: 28,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: config.accentColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(13)),
            ),
            child: Center(
              child: Text(
                widget.team.fullName.toUpperCase(),
                style: TextStyle(
                  color: config.textColor.withValues(alpha: 0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual award card for list rendering
  /// Simplified for image capture - no async season name loading
  Widget _buildAwardCard(PlayerAward award, _StyleConfig config) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: config.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: config.accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 36,
                color: config.accentColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  award.title.toUpperCase(),
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Generate the web URL for this player
  String _getPlayerWebUrl() {
    final databaseId = DatabaseService.instance.publicShareId ?? '';
    final baseUrl = 'https://team-sync-soccer.web.app';
    return '$baseUrl/#/team/$databaseId/season/${widget.player.seasonId}/players/${widget.player.id}';
  }

  _StyleConfig _getStyleConfig(PlayerCardStyle style) {
    switch (style) {
      case PlayerCardStyle.classic:
        return _StyleConfig(
          backgroundColor: Colors.white,
          borderColor: widget.team.color1,
          accentColor: widget.team.color1,
          textColor: Colors.black,
          photoBackgroundColor: Colors.grey[200]!,
          infoBackgroundColor: Colors.white,
        );
      case PlayerCardStyle.modern:
        return _StyleConfig(
          backgroundColor: Colors.grey[900]!,
          borderColor: widget.team.color1,
          accentColor: widget.team.color1,
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
          borderColor: widget.team.color1,
          accentColor: widget.team.color1,
          textColor: widget.team.color1,
          photoBackgroundColor: Colors.grey[900]!,
          infoBackgroundColor: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, widget.team.color1.withValues(alpha: 0.2)],
          ),
        );
    }
  }
}

/// Stat row widget for the back of the card
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final _StyleConfig config;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: config.accentColor,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: config.textColor.withValues(alpha: 0.8),
                fontSize: 26,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: config.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: config.accentColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: config.textColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
