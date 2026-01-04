import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/player.dart';

class PlayerImageGallery extends StatefulWidget {
  final Player player;
  final double size;
  final VoidCallback? onTap;

  const PlayerImageGallery({
    super.key,
    required this.player,
    this.size = 160,
    this.onTap,
    this.useLatestImages =
        true, // Default to true to always show best available images
  });

  final bool useLatestImages;

  @override
  State<PlayerImageGallery> createState() => _PlayerImageGalleryState();
}

class _PlayerImageGalleryState extends State<PlayerImageGallery> {
  int _currentIndex = 0;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(PlayerImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final images = <String>[];
    String? profileImage = widget.player.profileImage;
    String? actionPhoto = widget.player.actionPhoto;
    String? headshot = widget.player.headshot;

    if (widget.useLatestImages) {
      if (mounted) {
        setState(() {
          // Ideally show loading state, but for now just keep existing or empty
        });
      }

      try {
        final latestImages = await widget.player.findLatestAvailableImages();
        profileImage = latestImages['profileImage'];
        actionPhoto = latestImages['actionPhoto'];
        headshot = latestImages['headshot'];
      } catch (e) {
        debugPrint('Error fetching latest images: $e');
        // Fallback to widget.player images (already set)
      }
    }

    if (!mounted) return;

    // Order: Profile > Action > Headshot
    if (profileImage != null && profileImage.isNotEmpty) {
      images.add(profileImage);
    }
    if (actionPhoto != null && actionPhoto.isNotEmpty) {
      images.add(actionPhoto);
    }
    if (headshot != null && headshot.isNotEmpty) {
      images.add(headshot);
    }

    setState(() {
      _images = images;
      _currentIndex = 0;
    });
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Theme.of(context).colorScheme.primary,
      child: Center(
        child: Text(
          '${widget.player.firstName.isNotEmpty ? widget.player.firstName[0] : ''}${widget.player.lastName.isNotEmpty ? widget.player.lastName[0] : ''}',
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return ClipOval(child: _buildDefaultAvatar());
    }

    if (_images.length == 1) {
      return GestureDetector(
        onTap: widget.onTap,
        child: ClipOval(
          child: Image.network(
            _images.first,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipOval(
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: widget.size,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                items: _images.map((imgUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return GestureDetector(
                        onTap: widget.onTap,
                        child: Image.network(
                          imgUrl,
                          width: widget.size,
                          height: widget.size,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          // Dots indicator (only if multiple images)
          if (_images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _images.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withOpacity(_currentIndex == entry.key ? 0.9 : 0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
