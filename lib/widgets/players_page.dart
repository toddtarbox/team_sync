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
import 'package:team_sync/widgets/breadcrumbs.dart';
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
  File? _actionPhotoFile; // For action photos (baseball card style)

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4; // Large screens/desktop
    if (width > 600) return 3; // Tablets
    return 2; // Phones
  }

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
            Breadcrumbs(
              items: buildTeamBreadcrumbs(
                databaseId: DatabaseService.instance.publicShareId ?? '',
                teamName: widget.season.team.fullName,
                seasonName: widget.season.name,
                seasonId: widget.season.id,
                additionalLabel: 'Players',
              ),
            ),
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
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            _calculateCrossAxisCount(context);
                        final totalSpacing =
                            (crossAxisCount - 1) * 16; // crossAxisSpacing
                        final totalPadding = 32; // 16 left + 16 right
                        final availableWidth =
                            constraints.maxWidth - totalPadding - totalSpacing;
                        final itemWidth = availableWidth / crossAxisCount;

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: itemWidth / (itemWidth / 0.85),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
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
                              child: GestureDetector(
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
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Player avatar
                                        Flexible(
                                          flex: 3,
                                          child: ResponsivePlayerAvatar(
                                            player: player,
                                            avatarSize: 80,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Player name
                                        Flexible(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text(
                                              player.displayName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Player number
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.season.team.color1
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '#${player.number}',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: widget.season.team.color1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
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
    _actionPhotoFile = null; // Reset action photo file

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
                      const SizedBox(height: 16),
                      // Profile and Action Photo Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Profile Photo
                          Column(
                            children: [
                              InkWell(
                                onTap: kIsWeb
                                    ? null
                                    : () async {
                                        if (!SubscriptionService
                                            .instance.isSubscribed) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(AppLocalizations.of(
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
                                        final pickedFile = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (pickedFile != null) {
                                          setModalState(() {
                                            _imageFile = File(pickedFile.path);
                                          });
                                        }
                                      },
                                child: ResponsivePlayerAvatar(
                                    player: player,
                                    avatarSize: 56,
                                    isEdit: true),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Profile Photo',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          // Action Photo
                          Column(
                            children: [
                              InkWell(
                                onTap: kIsWeb
                                    ? null
                                    : () async {
                                        if (!SubscriptionService
                                            .instance.isSubscribed) {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(AppLocalizations.of(
                                                        context)!
                                                    .proFeature),
                                                content: const Text(
                                                    'Action photos for player cards are a Pro feature!'),
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
                                        final pickedFile = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (pickedFile != null) {
                                          setModalState(() {
                                            _actionPhotoFile =
                                                File(pickedFile.path);
                                          });
                                        }
                                      },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: widget.season.team.color1,
                                      width: 2,
                                    ),
                                  ),
                                  child: _actionPhotoFile != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.file(
                                            _actionPhotoFile!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : player.actionPhoto != null &&
                                              player.actionPhoto!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: player.actionPhoto!
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      player.actionPhoto!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                          Icons.photo_camera,
                                                          size: 28,
                                                          color: Colors.grey,
                                                        );
                                                      },
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Image.file(
                                                      File(player.actionPhoto!),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Icon(
                                                          Icons.photo_camera,
                                                          size: 28,
                                                          color: Colors.grey,
                                                        );
                                                      },
                                                    ),
                                            )
                                          : const Icon(
                                              Icons.photo_camera,
                                              size: 28,
                                              color: Colors.grey,
                                            ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Action Photo',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              const Text(
                                '(for player cards)',
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                                        String? actionPhotoUrl =
                                            player.actionPhoto;

                                        // Handle profile image upload
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

                                        // Handle action photo upload
                                        if (_actionPhotoFile != null) {
                                          if (player.actionPhoto != null &&
                                              player.actionPhoto!.isNotEmpty) {
                                            try {
                                              await FirebaseStorage.instance
                                                  .refFromURL(
                                                      player.actionPhoto!)
                                                  .delete();
                                            } catch (e) {
                                              // Image may not exist, so we can ignore.
                                            }
                                          }
                                          final actionStorageRef = FirebaseStorage
                                              .instance
                                              .ref()
                                              .child(
                                                  'player_action_photos/${DateTime.now().toIso8601String()}');
                                          await actionStorageRef
                                              .putFile(_actionPhotoFile!);
                                          actionPhotoUrl =
                                              await actionStorageRef
                                                  .getDownloadURL();
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
                                                        'profileImage':
                                                            imageUrl,
                                                        'actionPhoto':
                                                            actionPhotoUrl,
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
    _actionPhotoFile = null; // Reset action photo file

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
                                        // Check for existing players with the same name
                                        final nameParts = playerName.split(' ');
                                        final firstName = nameParts.first;
                                        final lastName = nameParts.length > 1
                                            ? nameParts.last
                                            : '';

                                        // Query all players in this team
                                        final allPlayers = await DatabaseService
                                            .instance
                                            .query('Players',
                                                orderByChild: 'teamId',
                                                equalTo: widget.season.teamId);

                                        // Check if any existing player has the same name
                                        final duplicates =
                                            allPlayers.where((p) {
                                          final existingFirst =
                                              (p['firstName'] ?? '')
                                                  .toString()
                                                  .toLowerCase();
                                          final existingLast =
                                              (p['lastName'] ?? '')
                                                  .toString()
                                                  .toLowerCase();
                                          return existingFirst ==
                                                  firstName.toLowerCase() &&
                                              existingLast ==
                                                  lastName.toLowerCase();
                                        }).toList();

                                        if (duplicates.isNotEmpty) {
                                          // Show confirmation dialog
                                          final shouldContinue =
                                              await showDialog<bool>(
                                            context: context,
                                            builder:
                                                (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Duplicate Player Name'),
                                                content: Text(
                                                  'A player named "$playerName" already exists. Are you sure you want to create another player with the same name?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .cancelButton),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          dialogContext, false);
                                                    },
                                                  ),
                                                  TextButton(
                                                    child: const Text(
                                                        'Create Anyway'),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                          dialogContext, true);
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (shouldContinue != true) {
                                            return; // User cancelled
                                          }
                                        }

                                        // Proceed with creating the player
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
