import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        widget.season.team.logoUrl != null &&
                widget.season.team.logoUrl!.isNotEmpty
            ? CircleAvatar(
                child: ClipOval(
                  child: Image.network(
                    widget.season.team.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(widget.season.team.fullName[0]);
                    },
                  ),
                ),
              )
            : Container(),
        widget.season.team.logoUrl != null
            ? const SizedBox(width: 10)
            : Container(),
        Text(widget.season.team.fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                    _pickSeasonPhoto();
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
                        return Text(widget.season.team.fullName[0]);
                      },
                    ),
                  ),
                ))
            : kIsWeb
                ? Container()
                : IconButton(
                    onPressed: () {
                      _pickSeasonPhoto();
                    },
                    icon: const Icon(Icons.photo)),
        logoUrl != null && logoUrl.isNotEmpty
            ? const SizedBox(width: 10)
            : Container(),
      ]),
    );
  }
}
