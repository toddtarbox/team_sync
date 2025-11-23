import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_award.dart';
import 'package:team_sync/models/player_highlight.dart';
import 'package:team_sync/models/season.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget for players to edit their own profile on web with PIN authentication
class PlayerProfileEditor extends StatefulWidget {
  final Player player;
  final VoidCallback onExitEditMode;

  const PlayerProfileEditor({
    super.key,
    required this.player,
    required this.onExitEditMode,
  });

  @override
  State<PlayerProfileEditor> createState() => _PlayerProfileEditorState();
}

class _PlayerProfileEditorState extends State<PlayerProfileEditor> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;
  File? _actionPhotoFile;
  String? _profileImageUrl;
  String? _actionPhotoUrl;
  bool _isUploading = false;

  Future<List<PlayerHighlight>>? _highlightsFuture;
  Future<List<PlayerAward>>? _awardsFuture;

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.player.profileImage;
    _actionPhotoUrl = widget.player.actionPhoto;
    _loadHighlights();
    _loadAwards();
  }

  void _loadHighlights() {
    setState(() {
      _highlightsFuture = PlayerHighlight.listFromPlayerId(widget.player.id);
    });
  }

  void _loadAwards() {
    setState(() {
      _awardsFuture = PlayerAward.listFromPlayerId(widget.player.id);
    });
  }

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isProfileImage) {
            _profileImageFile = File(pickedFile.path);
          } else {
            _actionPhotoFile = File(pickedFile.path);
          }
        });

        // Auto-upload on web
        if (kIsWeb) {
          await _uploadImage(isProfileImage);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage(bool isProfileImage) async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = isProfileImage ? _profileImageFile : _actionPhotoFile;
      final oldUrl = isProfileImage
          ? widget.player.profileImage
          : widget.player.actionPhoto;

      if (file != null) {
        // Delete old image if exists
        if (oldUrl != null && oldUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(oldUrl).delete();
          } catch (e) {
            // Image may not exist, ignore
          }
        }

        // Upload new image
        final path = isProfileImage
            ? 'player_images/${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}'
            : 'player_action_photos/${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}';

        final storageRef = FirebaseStorage.instance.ref().child(path);

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(file);
        }

        final downloadUrl = await storageRef.getDownloadURL();

        // Update player
        if (isProfileImage) {
          widget.player.profileImage = downloadUrl;
          _profileImageUrl = downloadUrl;
        } else {
          widget.player.actionPhoto = downloadUrl;
          _actionPhotoUrl = downloadUrl;
        }

        await widget.player.save();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.profileUpdated)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorUpdatingProfile(e.toString()))),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _profileImageFile = null;
        _actionPhotoFile = null;
      });
    }
  }

  void _showImageSourceDialog(bool isProfileImage) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(loc.camera),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isProfileImage);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(loc.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isProfileImage);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, size: 28),
                const SizedBox(width: 12),
                Text(
                  loc.editProfile,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: widget.onExitEditMode,
                  icon: const Icon(Icons.close),
                  label: Text(loc.exitEditMode),
                ),
              ],
            ),
            const Divider(height: 32),

            // Profile Picture Section
            _buildImageSection(
              title: loc.profilePicture,
              imageUrl: _profileImageUrl,
              imageFile: _profileImageFile,
              onUpload: () => _showImageSourceDialog(true),
              onRemove: () async {
                if (_profileImageUrl != null) {
                  try {
                    await FirebaseStorage.instance
                        .refFromURL(_profileImageUrl!)
                        .delete();
                  } catch (e) {
                    // Ignore
                  }
                  widget.player.profileImage = null;
                  await widget.player.save();
                  setState(() {
                    _profileImageUrl = null;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Action Photo Section
            _buildImageSection(
              title: loc.actionPhoto,
              imageUrl: _actionPhotoUrl,
              imageFile: _actionPhotoFile,
              onUpload: () => _showImageSourceDialog(false),
              onRemove: () async {
                if (_actionPhotoUrl != null) {
                  try {
                    await FirebaseStorage.instance
                        .refFromURL(_actionPhotoUrl!)
                        .delete();
                  } catch (e) {
                    // Ignore
                  }
                  widget.player.actionPhoto = null;
                  await widget.player.save();
                  setState(() {
                    _actionPhotoUrl = null;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            // Highlights Section
            _buildHighlightsSection(),

            const SizedBox(height: 24),

            // Awards Section
            _buildAwardsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String? imageUrl,
    required File? imageFile,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Image preview
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(imageFile.path, fit: BoxFit.cover)
                              : Image.file(imageFile, fit: BoxFit.cover),
                        )
                      : imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imageUrl, fit: BoxFit.cover),
                            )
                          : const Center(
                              child: Icon(Icons.person,
                                  size: 48, color: Colors.grey),
                            ),
            ),
            const SizedBox(width: 16),
            // Buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : onUpload,
                    icon: const Icon(Icons.upload),
                    label: Text(
                        imageUrl != null ? loc.changeImage : loc.uploadImage),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : onRemove,
                      icon: const Icon(Icons.delete),
                      label: Text(loc.removeImage),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                  if (!kIsWeb && imageFile != null) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _uploadImage(title == loc.profilePicture),
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(loc.save),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightsSection() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.highlights,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: () => _showAddHighlightDialog(),
              icon: const Icon(Icons.add),
              tooltip: loc.addHighlight,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<PlayerHighlight>>(
          future: _highlightsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text(
                  loc.errorLoadingHighlights(snapshot.error.toString()));
            }

            final highlights = snapshot.data ?? [];

            if (highlights.isEmpty) {
              return Text(
                loc.noHighlightsAvailable,
                style: const TextStyle(color: Colors.grey),
              );
            }

            return Column(
              children: highlights.map((h) => _buildHighlightCard(h)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHighlightCard(PlayerHighlight highlight) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.video_library),
        title: Text(highlight.title),
        subtitle: Text(
          '${highlight.date.month}/${highlight.date.day}/${highlight.date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () => _launchUrl(highlight.videoUrl),
              tooltip: loc.watchLabel,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddHighlightDialog(highlight: highlight),
              tooltip: loc.edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteHighlight(highlight),
              tooltip: loc.delete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAwardsSection() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.awards,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: () => _showAddAwardDialog(),
              icon: const Icon(Icons.add),
              tooltip: loc.addAward,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<PlayerAward>>(
          future: _awardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text(loc.errorLoadingAwards(snapshot.error.toString()));
            }

            final awards = snapshot.data ?? [];

            if (awards.isEmpty) {
              return Text(
                loc.noAwardsAvailable,
                style: const TextStyle(color: Colors.grey),
              );
            }

            return Column(
              children: awards.map((a) => _buildAwardCard(a)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAwardCard(PlayerAward award) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: award.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(award.imageUrl!),
              )
            : const Icon(Icons.emoji_events),
        title: Text(award.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (award.description != null) Text(award.description!),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FutureBuilder<String>(
                future: award.getSeasonName(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Season ${award.seasonId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddAwardDialog(award: award),
              tooltip: loc.edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteAward(award),
              tooltip: loc.delete,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHighlightDialog({PlayerHighlight? highlight}) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = highlight != null;
    final titleController = TextEditingController(text: highlight?.title ?? '');
    final descriptionController =
        TextEditingController(text: highlight?.description ?? '');
    final urlController =
        TextEditingController(text: highlight?.videoUrl ?? '');
    DateTime selectedDate = highlight?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? loc.editHighlight : loc.addHighlightDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.labelTitleRequired,
                    hintText: loc.hintTitleExample,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.labelDescription,
                    hintText: loc.hintDescriptionOptional,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: loc.labelVideoUrlRequired,
                    hintText: loc.hintVideoUrl,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.labelDate),
                  subtitle: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();

                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.titleUrlRequired)),
                  );
                  return;
                }

                try {
                  final h = PlayerHighlight(
                    id: highlight?.id ?? DateTime.now().millisecondsSinceEpoch,
                    playerId: widget.player.id,
                    title: title,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    videoUrl: url,
                    date: selectedDate,
                  );

                  await h.save();
                  _loadHighlights();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.highlightSaved)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(loc.errorSavingHighlight(e.toString()))),
                    );
                  }
                }
              },
              child: Text(isEdit ? loc.updateButton : loc.addButton),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAwardDialog({PlayerAward? award}) async {
    final loc = AppLocalizations.of(context)!;
    final isEdit = award != null;
    final titleController = TextEditingController(text: award?.title ?? '');
    final descriptionController =
        TextEditingController(text: award?.description ?? '');

    // Load available seasons for this player's team
    final seasons = await Season.fromTeamId(widget.player.teamId);

    // Find the season by ID if editing
    Season? selectedSeason;
    if (award != null && seasons.isNotEmpty) {
      selectedSeason = seasons.firstWhere(
        (s) => s.id == award.seasonId,
        orElse: () => seasons.first,
      );
    } else if (seasons.isNotEmpty) {
      selectedSeason = seasons.first;
    }

    String? imageUrl = award?.imageUrl;
    File? imageFile;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? loc.editAward : loc.addAwardDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.labelAwardTitle,
                    hintText: loc.hintAwardTitle,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.labelDescription,
                    hintText: loc.hintDescriptionOptional,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                // Season selector
                DropdownButtonFormField<Season>(
                  value: selectedSeason,
                  decoration: InputDecoration(
                    labelText: loc.season,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_month),
                  ),
                  items: seasons.map((season) {
                    return DropdownMenuItem(
                      value: season,
                      child: Text(season.name),
                    );
                  }).toList(),
                  onChanged: (season) {
                    setState(() {
                      selectedSeason = season;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Award image upload
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.labelAwardImage),
                    const SizedBox(height: 8),
                    if (imageUrl != null || imageFile != null)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageFile != null
                              ? (kIsWeb
                                  ? Image.network(imageFile!.path,
                                      fit: BoxFit.cover)
                                  : Image.file(imageFile!, fit: BoxFit.cover))
                              : Image.network(imageUrl!, fit: BoxFit.cover),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 500,
                          maxHeight: 500,
                        );
                        if (picked != null) {
                          setState(() {
                            imageFile = File(picked.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: Text(loc.uploadImage),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();

                if (title.isEmpty || selectedSeason == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.titleUrlRequired)),
                  );
                  return;
                }

                try {
                  // Upload image if new file selected
                  String? finalImageUrl = imageUrl;
                  if (imageFile != null) {
                    final path =
                        'player_awards/${widget.player.id}_${DateTime.now().millisecondsSinceEpoch}';
                    final storageRef =
                        FirebaseStorage.instance.ref().child(path);

                    if (kIsWeb) {
                      final bytes = await imageFile!.readAsBytes();
                      await storageRef.putData(bytes);
                    } else {
                      await storageRef.putFile(imageFile!);
                    }

                    finalImageUrl = await storageRef.getDownloadURL();
                  }

                  final a = PlayerAward(
                    id: award?.id ?? DateTime.now().millisecondsSinceEpoch,
                    playerId: widget.player.id,
                    seasonId: selectedSeason!.id,
                    title: title,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    imageUrl: finalImageUrl,
                  );

                  await a.save();
                  _loadAwards();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.awardSaved)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.errorSavingAward(e.toString()))),
                    );
                  }
                }
              },
              child: Text(isEdit ? loc.updateButton : loc.addButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHighlight(PlayerHighlight highlight) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteHighlightTitle),
        content: Text(loc.deleteHighlightConfirm(highlight.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await highlight.delete();
        _loadHighlights();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.highlightDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorDeletingHighlight(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteAward(PlayerAward award) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteAwardTitle),
        content: Text(loc.deleteAwardConfirm(award.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete image if exists
        if (award.imageUrl != null) {
          try {
            await FirebaseStorage.instance.refFromURL(award.imageUrl!).delete();
          } catch (e) {
            // Ignore
          }
        }

        await award.delete();
        _loadAwards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.awardDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorDeletingAward(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
