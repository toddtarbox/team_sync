import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

class SeasonRecord extends StatelessWidget {
  final List<Season> seasons;
  final bool singleSeason;

  const SeasonRecord(this.seasons, {this.singleSeason = true, super.key});

  @override
  Widget build(BuildContext context) {
    final games =
        seasons.map((s) => s.games).toList(growable: false).expand((i) => i);
    final team = seasons.first.team;
    final teamId = team.id;

    int wins = games.where((g) => g.isWin(teamId)).length;
    int losses = games
        .where((g) => g.gameStatus.index >= 9 && !g.isWin(teamId) && !g.isTie)
        .length;
    int ties = games.where((g) => g.isTie).length;

    final String leading = seasons.length > 1
        ? AppLocalizations.of(context)!.overall
        : AppLocalizations.of(context)!.season;

    final logoUrl = singleSeason ? seasons[0].logoUrl : team.logoUrl;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      logoUrl != null && logoUrl.isNotEmpty
          ? GestureDetector(
              onTap: () {
                if (singleSeason) {
                  _pickSeasonPhoto();
                }
              },
              onDoubleTap: () {
                if (singleSeason) {
                  _showSeasonPhoto(context);
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
                      return Text(team.fullName[0]);
                    },
                  ),
                ),
              ))
          : IconButton(
              onPressed: () {
                if (singleSeason) {
                  _pickSeasonPhoto();
                }
              },
              icon: Icon(Icons.photo)),
      logoUrl != null && logoUrl.isNotEmpty
          ? const SizedBox(width: 10)
          : Container(),
      Text('$leading Record ($wins - $losses - $ties)',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
    ]);
  }

  Future<void> _showSeasonPhoto(BuildContext context) async {
    if (seasons[0].logoUrl == null || seasons[0].logoUrl!.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(seasons[0].logoUrl!),
          ),
        );
      },
    );
  }

  Future<void> _pickSeasonPhoto() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (seasons[0].logoUrl != null && seasons[0].logoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(seasons[0].logoUrl!)
              .delete();
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
        where: 'id=?',
        whereArgs: [seasons[0].id],
      );
      seasons[0].logoUrl = imageUrl;
    }
  }
}
