import 'package:universal_io/io.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';
import 'package:team_sync/widgets/common/hover_builder.dart';

/// A common page header widget that displays team information with logo and name.
/// Use this below your AppBar for consistent team branding across pages.
class CommonPageHeader extends StatelessWidget {
  final Team team;
  final double? height;
  final EdgeInsets? padding;

  const CommonPageHeader({
    super.key,
    required this.team,
    this.height,
    this.padding,
    this.onTeamUpdated,
  });

  final VoidCallback? onTeamUpdated;

  @override
  Widget build(BuildContext context) {
    final responsiveAvatar = ResponsiveAvatar(
      key: const Key('team_logo'),
      backgroundColor: Colors.transparent,
      imageUrl: team.logoUrl,
      initials: team.fullName.isNotEmpty ? team.fullName[0] : '?',
      isSquare: team.isLogoSquare ?? false,
    );

    final organizationAvatar =
        team.organizationLogoUrl != null && team.organizationLogoUrl!.isNotEmpty
            ? ResponsiveAvatar(
                key: const Key('organization_logo'),
                backgroundColor: Colors.transparent,
                imageUrl: team.organizationLogoUrl,
                initials: team.fullName.isNotEmpty ? team.fullName[0] : '?',
                isSquare: team.isOrganizationLogoSquare ?? false,
              )
            : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height ?? 100,
          padding: padding ?? const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                team.color1,
                team.color2,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (team.logoUrl != null && team.logoUrl!.isNotEmpty) ...[
                HoverBuilder(
                  builder: (context, isHovered) {
                    return Transform.scale(
                      scale: kIsWeb && isHovered ? 1.05 : 1.0,
                      child: GestureDetector(
                        onTap: kIsWeb
                            ? () => _showLargeLogoView(context, team.logoUrl!)
                            : (team.isTeamAdmin(
                                    FirebaseAuth.instance.currentUser?.uid)
                                ? () => _showLogoOptions(context,
                                    isOrganizationLogo: false)
                                : null),
                        child: responsiveAvatar,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ] else if (!kIsWeb &&
                  team.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid)) ...[
                GestureDetector(
                  onTap: () =>
                      _showLogoOptions(context, isOrganizationLogo: false),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: !kIsWeb &&
                          team.isTeamAdmin(
                              FirebaseAuth.instance.currentUser?.uid)
                      ? () => _showEditNameDialog(context)
                      : null,
                  child: Text(
                    team.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (organizationAvatar != null) ...[
                const SizedBox(width: 10),
                HoverBuilder(
                  builder: (context, isHovered) {
                    return Transform.scale(
                      scale: kIsWeb && isHovered ? 1.05 : 1.0,
                      child: GestureDetector(
                        onTap: kIsWeb
                            ? () => _showLargeLogoView(
                                context, team.organizationLogoUrl!)
                            : (team.isTeamAdmin(
                                    FirebaseAuth.instance.currentUser?.uid)
                                ? () => _showLogoOptions(context,
                                    isOrganizationLogo: true)
                                : null),
                        child: organizationAvatar,
                      ),
                    );
                  },
                ),
              ] else if (!kIsWeb &&
                  team.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid)) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () =>
                      _showLogoOptions(context, isOrganizationLogo: true),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoOptions(BuildContext context,
      {required bool isOrganizationLogo}) async {
    final loc = AppLocalizations.of(context)!;
    final currentLogoUrl =
        isOrganizationLogo ? team.organizationLogoUrl : team.logoUrl;
    final hasLogo = currentLogoUrl != null && currentLogoUrl.isNotEmpty;
    final isSquare = isOrganizationLogo
        ? (team.isOrganizationLogoSquare ?? false)
        : (team.isLogoSquare ?? false);

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                isOrganizationLogo ? loc.organizationLogo : loc.teamLogo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            if (!isOrganizationLogo)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.renameTeam),
                onTap: () {
                  Navigator.pop(context);
                  _showEditNameDialog(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(hasLogo ? loc.changeLogo : loc.addLogo),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadLogo(context,
                    isOrganizationLogo: isOrganizationLogo);
              },
            ),
            if (hasLogo)
              ListTile(
                leading: Icon(
                  isSquare ? Icons.circle_outlined : Icons.crop_square,
                ),
                title: Text(isSquare ? 'Make Circle' : 'Make Square'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleLogoShape(context,
                      isOrganizationLogo: isOrganizationLogo);
                },
              ),
            if (hasLogo)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(loc.removeLogo),
                onTap: () {
                  Navigator.pop(context);
                  _removeLogo(context, isOrganizationLogo: isOrganizationLogo);
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(loc.cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context,
      {required bool isOrganizationLogo}) async {
    final loc = AppLocalizations.of(context)!;

    // Capture navigator and scaffold messenger BEFORE any async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      // Show loading indicator using navigator's context
      navigator.push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (BuildContext context, _, __) {
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(loc.uploadingImage),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Upload to Firebase Storage
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('User authenticated: $userId');

      final String path = isOrganizationLogo
          ? 'teams/${team.id}/organization_logo_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : 'teams/${team.id}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('Uploading to path: $path');

      final storageRef = FirebaseStorage.instance.ref().child(path);
      await storageRef.putFile(File(pickedFile.path));

      debugPrint('File uploaded, getting download URL...');

      final imageUrl = await storageRef.getDownloadURL();

      debugPrint('Download URL: $imageUrl');

      // Update database
      final fieldName = isOrganizationLogo ? 'organizationLogoUrl' : 'logoUrl';

      debugPrint('Updating database field: $fieldName');

      await DatabaseService.instance.update(
        'Teams',
        {fieldName: imageUrl},
        key: team.id.toString(),
      );
      Team.clearCache();

      debugPrint('Database updated successfully');

      // Dismiss loading dialog
      navigator.pop();

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(loc.logoUpdated)),
      );

      debugPrint('Calling onSummaryChanged callback');

      // Trigger callback to refresh parent widget
      onTeamUpdated?.call();
    } catch (e, stackTrace) {
      debugPrint('Error uploading logo: $e');
      debugPrint('Stack trace: $stackTrace');

      // Try to dismiss loading dialog if it's showing
      try {
        navigator.pop();
      } catch (_) {
        // Dialog might not be showing
      }

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              '${loc.errorSaving(e.toString())}\n\nPlease check your internet connection and try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _removeLogo(BuildContext context,
      {required bool isOrganizationLogo}) async {
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.removeLogo),
        content: Text(loc.confirmRemoveLogo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.remove),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final fieldName = isOrganizationLogo ? 'organizationLogoUrl' : 'logoUrl';
      await DatabaseService.instance.update(
        'Teams',
        {fieldName: null},
        key: team.id.toString(),
      );
      Team.clearCache();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.logoRemoved)),
        );

        // Trigger callback to refresh parent widget
        onTeamUpdated?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSaving(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleLogoShape(BuildContext context,
      {required bool isOrganizationLogo}) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final currentIsSquare = isOrganizationLogo
          ? (team.isOrganizationLogoSquare ?? false)
          : (team.isLogoSquare ?? false);

      final fieldName =
          isOrganizationLogo ? 'isOrganizationLogoSquare' : 'isLogoSquare';

      await DatabaseService.instance.update(
        'Teams',
        {fieldName: !currentIsSquare},
        key: team.id.toString(),
      );
      Team.clearCache();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentIsSquare
                ? 'Logo shape changed to square'
                : 'Logo shape changed to circle'),
          ),
        );

        // Trigger callback to refresh parent widget
        onTeamUpdated?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorSaving(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: team.fullName);
    final shortNameController = TextEditingController(text: team.shortName);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.renameTeam),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: loc.teamName,
                hintText: loc.teamName,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: shortNameController,
              decoration: InputDecoration(
                labelText: loc.teamShortName,
                hintText: loc.teamShortName,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.save),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      if (nameController.text.isEmpty || shortNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both names')),
        );
        return;
      }

      try {
        await DatabaseService.instance.update(
          'Teams',
          {
            'fullName': nameController.text,
            'shortName': shortNameController.text,
          },
          key: team.id.toString(),
        );
        Team.clearCache();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.teamNameUpdated)),
          );
          onTeamUpdated?.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.errorSaving(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showLargeLogoView(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
            // Image
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
