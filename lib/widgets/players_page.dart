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
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive_avatar.dart' as generic_avatar;
import 'package:team_sync/widgets/responsive_player_avatar.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

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
        appBar: buildStandardAppBar(
          context: context,
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
        body: Column(
          children: [
            CommonPageHeader(team: widget.season.team),
            Expanded(
              child: FutureBuilder(
                // Query by teamId using RTDB native query to reduce bandwidth, then
                // filter by seasonId and sort locally by firstName to keep original behavior.
                future: DatabaseService.instance.query('Players',
                    orderByChild: 'teamId', equalTo: widget.season.teamId),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasData) {
                    // Filter results to this season and sort by firstName ASC
                    final raw = snapshot.data!;
                    final players = raw
                        .where((p) => p['seasonId'] == widget.season.id)
                        .toList(growable: false);
                    players.sort((a, b) {
                      final af = (a['firstName'] ?? '').toString();
                      final bf = (b['firstName'] ?? '').toString();
                      return af.compareTo(bf);
                    });
                    return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = Player.fromMap(players[index]);
                          return Dismissible(
                              key: Key(player.id.toString()),
                              direction: DismissDirection
                                  .startToEnd, // Only allow right to left swipe
                              dismissThresholds: const {
                                DismissDirection.startToEnd:
                                    0.5, // Require 50% swipe to trigger
                              },
                              background: Container(color: Colors.red),
                              confirmDismiss: kIsWeb
                                  ? (_) => Future.value(false)
                                  : (_) {
                                      return showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                                AppLocalizations.of(context)!
                                                    .confirmDelete),
                                            content: Text(AppLocalizations.of(
                                                    context)!
                                                .areYouSureYouWantToDeleteThisPlayer),
                                            actions: [
                                              TextButton(
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .continueButton),
                                                onPressed: () {
                                                  Navigator.pop(context, true);
                                                },
                                              ),
                                              TextButton(
                                                child: Text(AppLocalizations.of(
                                                        context)!
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
                                // Find child keys where id==player.id and seasonId==widget.season.id
                                final candidates = await DatabaseService
                                    .instance
                                    .query('Players',
                                        orderByChild: 'id', equalTo: player.id);
                                for (final c in candidates) {
                                  if (c['seasonId'] == widget.season.id) {
                                    final k = c['_key']?.toString();
                                    if (k != null) {
                                      await DatabaseService.instance
                                          .delete('Players', key: k);
                                    }
                                  }
                                }
                                setState(() {});
                              },
                              child: ListTile(
                                onTap: kIsWeb
                                    ? () {
                                        final databaseId = DatabaseService
                                            .instance.publicShareId;
                                        if (databaseId != null) {
                                          NavigationHelper.navigateTo(
                                            context,
                                            '/team/$databaseId/season/${widget.season.id}/players/${player.id}',
                                            extra: {
                                              'player': player,
                                              'season': widget.season
                                            },
                                          );
                                        }
                                      }
                                    : () => _editPlayer(player),
                                onLongPress:
                                    kIsWeb ? null : () => _editPlayer(player),
                                leading: GestureDetector(
                                  onTap: kIsWeb
                                      ? () {
                                          final databaseId = DatabaseService
                                              .instance.publicShareId;
                                          if (databaseId != null) {
                                            NavigationHelper.navigateTo(
                                              context,
                                              '/team/$databaseId/season/${widget.season.id}/players/${player.id}',
                                              extra: {
                                                'player': player,
                                                'season': widget.season
                                              },
                                            );
                                          }
                                        }
                                      : () {
                                          if (!SubscriptionService
                                              .instance.isSubscribed) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .proFeature),
                                                  content: Text(AppLocalizations
                                                          .of(context)!
                                                      .playerProfilesProFeature),
                                                  actions: [
                                                    TextButton(
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .cancelButton),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .goPro),
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        await SubscriptionService
                                                            .instance
                                                            .purchaseSubscription();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            return;
                                          }
                                          final databaseId = DatabaseService
                                              .instance.publicShareId;
                                          if (databaseId != null) {
                                            NavigationHelper.navigateTo(
                                              context,
                                              '/team/$databaseId/season/${widget.season.id}/players/${player.id}',
                                              extra: {
                                                'player': player,
                                                'season': widget.season
                                              },
                                            );
                                          }
                                        },
                                  child: ResponsivePlayerAvatar(
                                      player: player, avatarSize: 40),
                                ),
                                title: Text(player.displayName),
                                subtitle: Text('#${player.number}'),
                              ));
                        });
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
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
                        onTap: kIsWeb
                            ? null
                            : () async {
                                if (!SubscriptionService
                                    .instance.isSubscribed) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .proFeature),
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .playerProfilesProFeature),
                                        actions: [
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .cancelButton),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .goPro),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await SubscriptionService.instance
                                                  .purchaseSubscription();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return;
                                }
                                final pickedFile = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  setModalState(() {
                                    _imageFile = File(pickedFile.path);
                                  });
                                }
                              },
                        child: ResponsivePlayerAvatar(
                            player: player, avatarSize: 56),
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

                                        // Safe RTDB update: locate child key(s) for this player id + seasonId
                                        final candidates = await DatabaseService
                                            .instance
                                            .query('Players',
                                                orderByChild: 'id',
                                                equalTo: player.id);
                                        for (final c in candidates) {
                                          if (c['seasonId'] ==
                                              widget.season.id) {
                                            final k = c['_key']?.toString();
                                            if (k != null) {
                                              await DatabaseService.instance
                                                  .update(
                                                      'Players',
                                                      {
                                                        'firstName': firstName,
                                                        'lastName': lastName,
                                                        'number': playerNumber,
                                                        'profileImage': imageUrl
                                                      },
                                                      key: k);
                                            }
                                          }
                                        }

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
                        child: generic_avatar.ResponsiveAvatar(
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          initials: '',
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
                                          'id': DateTime.now()
                                              .millisecondsSinceEpoch,
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
