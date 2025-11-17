import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/season_record.dart';

class SeasonsListView extends StatefulWidget {
  const SeasonsListView({
    super.key,
    required this.seasons,
  });

  final List<Season> seasons;

  @override
  State<SeasonsListView> createState() => _SeasonsListViewState();
}

class _SeasonsListViewState extends State<SeasonsListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.seasons.length,
        itemBuilder: (context, index) {
          final season = widget.seasons[index];
          final logoUrl = season.logoUrl;
          final databaseId = DatabaseService.instance.publicShareId;

          final seasonCard = GestureDetector(
              onTap: () {
                if (databaseId != null) {
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/season/${season.id}',
                      extra: season);
                }
              },
              child: Card(
                  child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(season.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  logoUrl != null && logoUrl.isNotEmpty
                      ? const SizedBox(width: 10)
                      : Container(),
                  logoUrl != null && logoUrl.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _showSeasonPhoto(context, logoUrl);
                          },
                          onDoubleTap: () {
                            if (!kIsWeb) {
                              _pickSeasonPhoto(season);
                            } else {
                              _showSeasonPhoto(context, logoUrl);
                            }
                          },
                          child: CircleAvatar(
                            child: ClipOval(
                              child: Image.network(
                                logoUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(season.team.fullName[0]);
                                },
                              ),
                            ),
                          ))
                      : kIsWeb
                          ? Container()
                          : IconButton(
                              onPressed: () {
                                _pickSeasonPhoto(season);
                              },
                              icon: const Icon(Icons.photo)),
                  logoUrl != null && logoUrl.isNotEmpty
                      ? const SizedBox(width: 10)
                      : Container(),
                ]),
                Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.all(10),
                    child: Center(child: SeasonRecord([season]))),
              ])));
          return Dismissible(
              key: Key(season.id.toString()),
              direction:
                  DismissDirection.startToEnd, // Only allow right to left swipe
              dismissThresholds: const {
                DismissDirection.startToEnd:
                    0.5, // Require 50% swipe to trigger
              },
              background: Container(color: Theme.of(context).colorScheme.error),
              behavior: HitTestBehavior.translucent,
              confirmDismiss: kIsWeb
                  ? (_) => Future.value(false)
                  : (_) {
                      return showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                AppLocalizations.of(context)!.confirmDelete),
                            content: Text(AppLocalizations.of(context)!
                                .areYouSureYouWantToDeleteThisSeason),
                            actions: [
                              TextButton(
                                child: Text(AppLocalizations.of(context)!
                                    .continueButton),
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                              ),
                              TextButton(
                                child: Text(
                                    AppLocalizations.of(context)!.cancelButton),
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
              onDismissed: (direction) async {
                await DatabaseService.instance
                    .delete('Seasons', key: season.id.toString());
                widget.seasons.removeAt(index);
                setState(() {});
              },
              child: seasonCard);
        });
  }

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

  Future<void> _pickSeasonPhoto(Season season) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (season.logoUrl != null && season.logoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(season.logoUrl!).delete();
        } catch (e) {
          // Image may not exist, so we can ignore.
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
        key: season.id.toString(),
      );
      season.logoUrl = imageUrl;
    }
  }
}
