import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:team_sync/features/players/models/player_award.dart';
import 'package:team_sync/features/players/models/player_highlight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Full-screen highlight reel player that loops through awards and highlights
/// with smooth animations and video playback support
class HighlightReelPlayer extends StatefulWidget {
  final List<PlayerAward> awards;
  final List<PlayerHighlight> highlights;
  final String playerName;

  const HighlightReelPlayer({
    super.key,
    required this.awards,
    required this.highlights,
    required this.playerName,
  });

  @override
  State<HighlightReelPlayer> createState() => _HighlightReelPlayerState();
}

class _HighlightReelPlayerState extends State<HighlightReelPlayer>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  bool _isLoading = false;
  bool _isPaused = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _itemDurationController; // For non-video items
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _areControlsVisible = true;
  Timer? _controlsTimer;
  bool _isMuted = false;

  List<dynamic> _allItems = [];

  @override
  void initState() {
    super.initState();

    // Combine awards and highlights
    _allItems = [...widget.awards, ...widget.highlights];

    if (_allItems.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _itemDurationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _itemDurationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNext();
      }
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Lock orientation to landscape for better viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI for fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadCurrentItem();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controlsTimer?.cancel();
    _videoController?.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _itemDurationController.dispose();

    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  void _loadCurrentItem() async {
    if (_currentIndex >= _allItems.length) return;

    final item = _allItems[_currentIndex];

    setState(() {
      _isLoading = true;
    });

    final oldController = _videoController;

    setState(() {
      _isLoading = true;
      _videoController = null;
      _isVideoPlaying = false;
    });

    // Stop previous video if any
    try {
      await oldController?.pause();
      await oldController?.dispose();
    } catch (e) {
      debugPrint('Error disposing old controller: $e');
    }

    if (!mounted) return;

    // Play entry animations
    _fadeController.forward(from: 0);
    _scaleController.forward(from: 0);
    _slideController.forward(from: 0);
    _itemDurationController.reset();

    if (item is PlayerHighlight && item.videoUrl.isNotEmpty) {
      debugPrint('PlayerHighlight video URL: ${item.videoUrl}');

      // Check if this is an external URL (YouTube, Vimeo, Google Drive, etc.) that can't be embedded
      final isExternalVideo = item.videoUrl.contains('youtube.com') ||
          item.videoUrl.contains('youtu.be') ||
          item.videoUrl.contains('vimeo.com') ||
          item.videoUrl.contains('hudl.com') ||
          item.videoUrl.contains('drive.google.com') ||
          item.videoUrl.contains('docs.google.com');

      debugPrint('Is external video: $isExternalVideo');

      if (isExternalVideo) {
        // For external videos, just show for a duration (like images)
        // The user can tap to open in browser
        debugPrint('Showing external video placeholder');
        setState(() {
          _isLoading = false;
        });
        if (!_isPaused) {
          _itemDurationController.forward();
        }
      } else {
        // Try to load and play video directly (for direct video URLs)
        debugPrint('Attempting to load direct video');
        try {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(item.videoUrl),
          );

          await _videoController!.initialize();

          if (!mounted) return;

          setState(() {
            _isVideoPlaying = true;
            _isLoading = false;
          });

          _videoController!.play();
          _videoController!.setLooping(false);
          _videoController!.setVolume(_isMuted ? 0.0 : 1.0);

          // Listen for video completion
          _videoController!.addListener(() {
            if (!mounted) return;
            // Check if controller is valid and initialized
            if (_videoController != null &&
                _videoController!.value.isInitialized &&
                _videoController!.value.position >=
                    _videoController!.value.duration) {
              _goToNext();
            }
          });
        } catch (e) {
          debugPrint('Error loading video: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isVideoPlaying = false;
              _videoController = null;
            });
            if (!_isPaused) {
              _itemDurationController.forward();
            }
          }
        }
      }
    } else if (item is PlayerAward) {
      debugPrint('PlayerAward item');
      // Show image for a duration
      setState(() {
        _isLoading = false;
      });
      if (!_isPaused) {
        _itemDurationController.forward();
      }
    } else {
      debugPrint('Unknown item type or empty video URL');
      // Unknown type or empty URL
      setState(() {
        _isLoading = false;
      });
      if (!_isPaused) {
        _itemDurationController.forward();
      }
    }
  }

  void _startHideControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _areControlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    if (_areControlsVisible) {
      _startHideControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    _showControls();
  }

  void _goToNext() {
    _autoPlayTimer?.cancel();

    setState(() {
      _currentIndex = (_currentIndex + 1) % _allItems.length;
    });

    _loadCurrentItem();
  }

  void _goToPrevious() {
    _autoPlayTimer?.cancel();

    setState(() {
      _currentIndex = (_currentIndex - 1 + _allItems.length) % _allItems.length;
    });

    _loadCurrentItem();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _autoPlayTimer?.cancel();
      _videoController?.pause();
      if (_itemDurationController.isAnimating) {
        _itemDurationController.stop();
      }
    } else {
      if (_isVideoPlaying) {
        _videoController?.play();
      } else {
        _itemDurationController.forward();
      }
    }
    _showControls();
  }

  @override
  Widget build(BuildContext context) {
    if (_allItems.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Center(
                child: Text(
                  'No highlights to show',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                label:
                    const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = _allItems[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeAnimation,
                  _scaleAnimation,
                  _slideAnimation,
                ]),
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildItemContent(currentItem),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top info bar
            // Top info bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Close button - ALWAYS VISIBLE
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 16),

                        // Player info - FADE IN/OUT
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: _areControlsVisible ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.playerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_currentIndex + 1} / ${_allItems.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and description - ALWAYS VISIBLE
                        Text(
                          _getItemTitle(currentItem),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_getItemDescription(currentItem) != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _getItemDescription(currentItem)!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Progress bar and Controls - FADE IN/OUT
                        IgnorePointer(
                          ignoring: !_areControlsVisible,
                          child: AnimatedOpacity(
                            opacity: _areControlsVisible ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Progress bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildProgressBar(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Control buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.skip_previous,
                                          color: Colors.white, size: 36),
                                      onPressed: () {
                                        _showControls();
                                        _goToPrevious();
                                      },
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: Icon(
                                        _isPaused
                                            ? Icons.play_arrow
                                            : Icons.pause,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      onPressed: _togglePause,
                                    ),
                                    const SizedBox(width: 24),
                                    IconButton(
                                      icon: const Icon(Icons.skip_next,
                                          color: Colors.white, size: 36),
                                      onPressed: () {
                                        _showControls();
                                        _goToNext();
                                      },
                                    ),
                                    if (_isVideoPlaying) ...[
                                      const SizedBox(width: 24),
                                      IconButton(
                                        icon: Icon(
                                          _isMuted
                                              ? Icons.volume_off
                                              : Icons.volume_up,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        onPressed: _toggleMute,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Pause indicator
            if (_isPaused && !_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemContent(dynamic item) {
    if (item is PlayerHighlight) {
      if (_isVideoPlaying && _videoController != null) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      } else {
        // Show video icon placeholder with play button for external videos
        final isExternalVideo = item.videoUrl.contains('youtube.com') ||
            item.videoUrl.contains('youtu.be') ||
            item.videoUrl.contains('vimeo.com') ||
            item.videoUrl.contains('hudl.com') ||
            item.videoUrl.contains('drive.google.com') ||
            item.videoUrl.contains('docs.google.com');

        return GestureDetector(
          onTap:
              isExternalVideo ? () => _openExternalVideo(item.videoUrl) : null,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPlaceholder(Icons.video_library),
                if (isExternalVideo)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 80,
                        color: Colors.red,
                      ),
                    ),
                  ),
                if (isExternalVideo)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Tap to watch video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    } else if (item is PlayerAward) {
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        return Image.network(
          item.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(Icons.emoji_events);
          },
        );
      } else {
        return _buildPlaceholder(Icons.emoji_events);
      }
    }

    return _buildPlaceholder(Icons.star);
  }

  void _openExternalVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Icon(
        icon,
        size: 120,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_isVideoPlaying && _videoController != null) {
      return VideoProgressIndicator(
        _videoController!,
        allowScrubbing: true,
        colors: VideoProgressColors(
          playedColor: Colors.white,
          bufferedColor: Colors.white.withValues(alpha: 0.3),
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
      );
    } else {
      // Animated progress bar for images/external videos
      return AnimatedBuilder(
        animation: _itemDurationController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _itemDurationController.value,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          );
        },
      );
    }
  }

  String _getItemTitle(dynamic item) {
    if (item is PlayerHighlight) {
      return item.title;
    } else if (item is PlayerAward) {
      return item.title;
    }
    return '';
  }

  String? _getItemDescription(dynamic item) {
    if (item is PlayerHighlight) {
      return item.description;
    } else if (item is PlayerAward) {
      return item.description;
    }
    return null;
  }
}
