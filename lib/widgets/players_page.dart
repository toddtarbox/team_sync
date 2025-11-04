import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';

class PlayersPage extends StatefulWidget {
  final Season season;
  const PlayersPage({super.key, required this.season});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          team: widget.season.team,
          title: Text(AppLocalizations.of(context)!.players,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        floatingActionButton: kIsWeb
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.season.team.color1,
                      widget.season.team.color2
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.add),
                  onPressed: () {
                    _createPlayer();
                  },
                )),
        body: FutureBuilder(
          future: DatabaseService.instance.query('Players',
              where: 'seasonId=? AND teamId=?',
              whereArgs: [widget.season.id, widget.season.teamId],
              orderBy: "firstName ASC"),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData) {
              final players = snapshot.data!;
              return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = Player.fromMap(players[index]);
                    return Dismissible(
                        key: Key(player.id.toString()),
                        background: Container(color: Colors.red),
                        confirmDismiss: kIsWeb
                            ? (_) => Future.value(false)
                            : (_) {
                                return showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(AppLocalizations.of(context)!
                                          .confirmDelete),
                                      content: Text(AppLocalizations.of(
                                              context)!
                                          .areYouSureYouWantToDeleteThisPlayer),
                                      actions: [
                                        TextButton(
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .continueButton),
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                        ),
                                        TextButton(
                                          child: Text(
                                              AppLocalizations.of(context)!
                                                  .cancelButton),
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
                          if (player.profileImage != null &&
                              player.profileImage!.isNotEmpty) {
                            try {
                              await FirebaseStorage.instance
                                  .refFromURL(player.profileImage!)
                                  .delete();
                            } catch (e) {
                              // Image may not exist, so we can ignore.
                            }
                          }
                          await DatabaseService.instance.delete('Players',
                              where: 'id=? AND seasonId=?',
                              whereArgs: [player.id, widget.season.id]);
                          setState(() {});
                        },
                        child: ListTile(
                          onTap: () => _editPlayer(player),
                          leading: CircleAvatar(
                            child: player.profileImage != null &&
                                    player.profileImage!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      player.profileImage!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Text(
                                            '${player.firstName[0]}${player.lastName[0]}');
                                      },
                                    ),
                                  )
                                : Text(
                                    '${player.firstName[0]}${player.lastName[0]}'),
                          ),
                          title: Text(player.displayName),
                          subtitle: Text('#${player.number}'),
                        ));
                  });
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }

  void _editPlayer(Player player) {
    late String playerName = player.displayName;
    late int playerNumber = player.number;
    _imageFile = null;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(children: [
                      Text(AppLocalizations.of(context)!.editPlayer),
                      GestureDetector(
                        onTap: SubscriptionService.instance.isSubscribed
                            ? () async {
                                final pickedFile = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  setModalState(() {
                                    _imageFile = File(pickedFile.path);
                                  });
                                }
                              }
                            : null,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (player.profileImage != null &&
                                      player.profileImage!.isNotEmpty
                                  ? NetworkImage(player.profileImage!)
                                  : null) as ImageProvider?,
                          child: _imageFile == null &&
                                  (player.profileImage == null ||
                                      player.profileImage!.isEmpty)
                              ? const Icon(Icons.add_a_photo)
                              : null,
                        ),
                      ),
                      TextFormField(
                          initialValue: playerName,
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.playerName),
                          onChanged: (name) => playerName = name),
                      TextFormField(
                          initialValue: playerNumber.toString(),
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.playerNumber),
                          onChanged: (number) =>
                              playerNumber = int.parse(number)),
                      const Spacer(),
                      TextButton(
                          onPressed: () {},
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () async {
                                      if (playerName.isNotEmpty) {
                                        String? imageUrl = player.profileImage;
                                        if (_imageFile != null) {
                                          if (player.profileImage != null &&
                                              player.profileImage!.isNotEmpty) {
                                            try {
                                              await FirebaseStorage.instance
                                                  .refFromURL(
                                                      player.profileImage!)
                                                  .delete();
                                            } catch (e) {
                                              // Image may not exist, so we can ignore.
                                            }
                                          }
                                          final storageRef = FirebaseStorage
                                              .instance
                                              .ref()
                                              .child(
                                                  'player_images/${DateTime.now().toIso8601String()}');
                                          await storageRef.putFile(_imageFile!);
                                          imageUrl =
                                              await storageRef.getDownloadURL();
                                        }

                                        final nameParts = playerName.split(' ');
                                        final firstName = nameParts.first;
                                        final lastName = nameParts.length > 1
                                            ? nameParts.last
                                            : '';

                                        await DatabaseService.instance.update(
                                            'Players',
                                            {
                                              'firstName': firstName,
                                              'lastName': lastName,
                                              'number': playerNumber,
                                              'profileImage': imageUrl
                                            },
                                            where: 'id=? AND seasonId=?',
                                            whereArgs: [
                                              player.id,
                                              widget.season.id
                                            ]);

                                        setState(() {});
                                        Navigator.pop(context);
                                      }
                                    }),
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .cancelButton,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () {
                                      Navigator.pop(context);
                                    })
                              ]))
                    ])));
          });
        });
  }

  void _createPlayer() {
    late String playerName;
    late int playerNumber;
    _imageFile = null;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(children: [
                      Text(AppLocalizations.of(context)!.newPlayer),
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setModalState(() {
                              _imageFile = File(pickedFile.path);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? const Icon(Icons.add_a_photo)
                              : null,
                        ),
                      ),
                      TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.playerName),
                          onChanged: (name) => playerName = name),
                      TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.playerNumber),
                          onChanged: (number) =>
                              playerNumber = int.parse(number)),
                      const Spacer(),
                      TextButton(
                          onPressed: () {},
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () async {
                                      if (playerName.isNotEmpty) {
                                        String? imageUrl;
                                        if (_imageFile != null) {
                                          final storageRef = FirebaseStorage
                                              .instance
                                              .ref()
                                              .child(
                                                  'player_images/${DateTime.now().toIso8601String()}');
                                          await storageRef.putFile(_imageFile!);
                                          imageUrl =
                                              await storageRef.getDownloadURL();
                                        }

                                        final nameParts = playerName.split(' ');
                                        final firstName = nameParts.first;
                                        final lastName = nameParts.length > 1
                                            ? nameParts.last
                                            : '';

                                        await DatabaseService.instance
                                            .insert('Players', {
                                          'firstName': firstName,
                                          'lastName': lastName,
                                          'number': playerNumber,
                                          'seasonId': widget.season.id,
                                          'teamId': widget.season.teamId,
                                          'profileImage': imageUrl
                                        });

                                        setState(() {});
                                        Navigator.pop(context);
                                      }
                                    }),
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .cancelButton,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () {
                                      Navigator.pop(context);
                                    })
                              ]))
                    ])));
          });
        });
  }
}
