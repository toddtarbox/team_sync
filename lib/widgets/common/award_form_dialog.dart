import 'package:universal_io/io.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/widgets/common/tappable_image.dart';

/// Data class to hold form results
class AwardFormData {
  final String title;
  final String? description;
  final String? url;
  final int? year;
  final List<String> imageUrls;
  final int displayOrder;

  const AwardFormData({
    required this.title,
    this.description,
    this.url,
    this.year,
    this.imageUrls = const [],
    this.displayOrder = 0,
  });
}

/// A universal form dialog component for adding/editing awards and accomplishments
///
/// This component provides consistent form UI and behavior for:
/// - Team Awards
/// - Player Awards
/// - Team Accomplishments
///
/// Features:
/// - Title, description, URL, year fields
/// - Single or multiple image upload
/// - Display order field (optional)
/// - Image preview with delete
/// - Form validation
/// - Loading states
/// - Error handling
///
/// Usage:
/// ```dart
/// final result = await AwardFormDialog.show(
///   context,
///   title: 'Add Team Award',
///   onSubmit: (data) async {
///     await saveAward(data);
///   },
///   allowMultipleImages: false,
/// );
/// ```
class AwardFormDialog extends StatefulWidget {
  /// Dialog title
  final String dialogTitle;

  /// Initial values (for editing)
  final String? initialTitle;
  final String? initialDescription;
  final String? initialUrl;
  final int? initialYear;
  final String? initialImageUrl;
  final List<String>? initialImageUrls;
  final int? initialDisplayOrder;

  /// Configuration
  final bool allowMultipleImages;
  final bool showYearField;
  final bool showDisplayOrderField;
  final String titleLabel;
  final String titleHint;
  final String submitButtonText;

  /// Callbacks
  final Future<void> Function(AwardFormData) onSubmit;
  final VoidCallback? onDelete;

  const AwardFormDialog({
    super.key,
    required this.dialogTitle,
    required this.onSubmit,
    this.initialTitle,
    this.initialDescription,
    this.initialUrl,
    this.initialYear,
    this.initialImageUrl,
    this.initialImageUrls,
    this.initialDisplayOrder,
    this.allowMultipleImages = false,
    this.showYearField = true,
    this.showDisplayOrderField = true,
    this.titleLabel = 'Title',
    this.titleHint = 'e.g., State Champions',
    this.submitButtonText = 'Save',
    this.onDelete,
  });

  /// Static method to show the dialog
  static Future<AwardFormData?> show(
    BuildContext context, {
    required String dialogTitle,
    required Future<void> Function(AwardFormData) onSubmit,
    String? initialTitle,
    String? initialDescription,
    String? initialUrl,
    int? initialYear,
    String? initialImageUrl,
    List<String>? initialImageUrls,
    int? initialDisplayOrder,
    bool allowMultipleImages = false,
    bool showYearField = true,
    bool showDisplayOrderField = true,
    String titleLabel = 'Title',
    String titleHint = 'e.g., State Champions',
    String submitButtonText = 'Save',
    VoidCallback? onDelete,
  }) {
    return showDialog<AwardFormData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AwardFormDialog(
        dialogTitle: dialogTitle,
        onSubmit: onSubmit,
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        initialUrl: initialUrl,
        initialYear: initialYear,
        initialImageUrl: initialImageUrl,
        initialImageUrls: initialImageUrls,
        initialDisplayOrder: initialDisplayOrder,
        allowMultipleImages: allowMultipleImages,
        showYearField: showYearField,
        showDisplayOrderField: showDisplayOrderField,
        titleLabel: titleLabel,
        titleHint: titleHint,
        submitButtonText: submitButtonText,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<AwardFormDialog> createState() => _AwardFormDialogState();
}

class _AwardFormDialogState extends State<AwardFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late final TextEditingController _yearController;
  late final TextEditingController _displayOrderController;

  final List<String> _imageUrls = [];
  bool _isUploadingImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _urlController = TextEditingController(text: widget.initialUrl);
    _yearController = TextEditingController(
      text: widget.initialYear?.toString() ?? '',
    );
    _displayOrderController = TextEditingController(
      text: widget.initialDisplayOrder?.toString() ?? '0',
    );

    // Initialize image URLs
    if (widget.initialImageUrls != null &&
        widget.initialImageUrls!.isNotEmpty) {
      _imageUrls.addAll(widget.initialImageUrls!);
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      _imageUrls.add(widget.initialImageUrl!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _yearController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (kIsWeb) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final List<XFile> pickedFiles;

      if (widget.allowMultipleImages) {
        pickedFiles = await ImagePicker().pickMultiImage();
      } else {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        pickedFiles = pickedFile != null ? [pickedFile] : [];
      }

      if (pickedFiles.isNotEmpty) {
        int uploadedCount = 0;
        for (final pickedFile in pickedFiles) {
          try {
            // Upload to Firebase Storage
            final storageRef = FirebaseStorage.instance.ref().child(
                'award_images/${DateTime.now().millisecondsSinceEpoch}_$uploadedCount.jpg');
            await storageRef.putFile(File(pickedFile.path));
            final downloadUrl = await storageRef.getDownloadURL();

            if (mounted) {
              setState(() {
                _imageUrls.add(downloadUrl);
              });
            }
            uploadedCount++;
          } catch (uploadError) {
            debugPrint('Error uploading image $uploadedCount: $uploadError');
          }
        }

        if (mounted && uploadedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                uploadedCount == pickedFiles.length
                    ? 'Successfully uploaded $uploadedCount image${uploadedCount == 1 ? '' : 's'}'
                    : 'Uploaded $uploadedCount of ${pickedFiles.length} images',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorUploadingImages(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.titleLabel} is required')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = AwardFormData(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        year: int.tryParse(_yearController.text.trim()),
        imageUrls: _imageUrls,
        displayOrder: int.tryParse(_displayOrderController.text.trim()) ?? 0,
      );

      await widget.onSubmit(data);

      if (mounted) {
        Navigator.pop(context, data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSaving(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isSaving && !_isUploadingImage,
      child: AlertDialog(
        title: Text(widget.dialogTitle),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: '${widget.titleLabel} *',
                    hintText: widget.titleHint,
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 12),

                // Description field
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.description,
                    hintText: loc.optionalDetails,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),

                // Year field (optional)
                if (widget.showYearField) ...[
                  TextField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: loc.year,
                      hintText: 'e.g., 2024',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                ],

                // Image upload section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Images',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_imageUrls.length} image${_imageUrls.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (widget.allowMultipleImages && !kIsWeb)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'You can select multiple images at once',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Image grid
                    if (_imageUrls.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _imageUrls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  TappableImage.network(
                                    imageUrl: url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: IconButton(
                                      icon: const Icon(Icons.cancel,
                                          color: Colors.red),
                                      onPressed: () => _removeImage(index),
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Add images button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isUploadingImage || kIsWeb ? null : _pickImages,
                        icon: _isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate),
                        label: Text(
                          _isUploadingImage
                              ? 'Uploading...'
                              : kIsWeb
                                  ? 'Image upload requires mobile app'
                                  : widget.allowMultipleImages
                                      ? 'Add Images'
                                      : 'Add Image',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // URL field
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: loc.linkURL,
                    hintText: loc.optionalExternalLink,
                  ),
                ),
                const SizedBox(height: 12),

                // Display order field (optional)
                if (widget.showDisplayOrderField) ...[
                  TextField(
                    controller: _displayOrderController,
                    decoration: InputDecoration(
                      labelText: loc.displayOrder,
                      hintText: '0 = first, higher = later',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          // Delete button (if editing and callback provided)
          if (widget.onDelete != null)
            TextButton(
              onPressed:
                  _isSaving || _isUploadingImage ? null : widget.onDelete,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(loc.delete),
            ),

          // Cancel button
          TextButton(
            onPressed: _isSaving || _isUploadingImage
                ? null
                : () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),

          // Submit button
          TextButton(
            onPressed: _isSaving || _isUploadingImage ? null : _submit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_isSaving ? 'Saving...' : widget.submitButtonText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
