import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

class SeasonWithLogo extends StatefulWidget {
  final Season season;

  const SeasonWithLogo({super.key, required this.season});

  @override
  State<SeasonWithLogo> createState() => _SeasonWithLogoState();
}

class _SeasonWithLogoState extends State<SeasonWithLogo> {
  Future<void> _showSeasonPhoto(BuildContext context, String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(logoUrl),
          ),
        );
      },
    );
  }

  Future<void> _pickSeasonPhoto() async {
    if (kIsWeb) return;
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (widget.season.logoUrl != null && widget.season.logoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(widget.season.logoUrl!)
              .delete();
        } catch (e) {
          // ignore
        }
      }
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('player_images/${DateTime.now().toIso8601String()}');
      await storageRef.putFile(File(pickedFile.path));
      final imageUrl = await storageRef.getDownloadURL();

      await DatabaseService.instance.update(
        'Seasons',
        {'logoUrl': imageUrl},
        key: widget.season.id.toString(),
      );

      setState(() {
        widget.season.logoUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.season.logoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Season image banner (if available)
        if (logoUrl != null && logoUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              _showSeasonPhoto(context, logoUrl);
            },
            onDoubleTap: () {
              if (!kIsWeb) {
                _pickSeasonPhoto();
              }
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(logoUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay at bottom for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Double-tap hint for mobile (only on mobile)
                  if (!kIsWeb)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Double-tap to change',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
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
        // Season name header with team logo
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.season.team.logoUrl != null &&
                  widget.season.team.logoUrl!.isNotEmpty) ...[
                ResponsiveAvatar(
                  size: 20,
                  imageUrl: widget.season.team.logoUrl,
                  initials: widget.season.team.fullName[0],
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.season.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Add image button if no logo exists (mobile only)
              if (!kIsWeb && (logoUrl == null || logoUrl.isEmpty)) ...[
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  onPressed: _pickSeasonPhoto,
                  tooltip: 'Add season image',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
