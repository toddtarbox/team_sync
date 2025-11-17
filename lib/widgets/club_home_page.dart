import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/config/database_collections.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/club_stats.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/admin_service.dart';
import 'package:team_sync/services/auth_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/admin_management_dialog.dart';
import 'package:team_sync/widgets/custom_appbar.dart';

class ClubHomePage extends StatefulWidget {
  final String? clubId;
  const ClubHomePage({super.key, this.clubId});

  @override
  State<ClubHomePage> createState() => _ClubHomePageState();
}

class _ClubHomePageState extends State<ClubHomePage> {
  Club? _club;
  List<Team> _teams = [];
  ClubStats? _clubStats;
  bool _isLoading = false;
  late bool _isSubscribed;
  late Future<bool> _loadFuture;
  List<Club> _allClubs = [];
  StreamSubscription<bool>? _subscriptionListener;
  bool _isNavigatingToSignIn = false;

  @override
  void initState() {
    super.initState();
    _subscriptionListener =
        SubscriptionService.instance.subscriptionState.listen((isSubscribed) {
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
        });
      }
    });
    _isSubscribed = SubscriptionService.instance.isSubscribed;
    DatabaseService.instance.setProvider(FirebaseDBProvider());
    _loadFuture = _load(); // Create the future once
  }

  @override
  void dispose() {
    _subscriptionListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a temporary team object with club colors for the appbar gradient
    final Team? clubTeam = _club != null
        ? Team(
            id: _club!.id,
            fullName: _club!.name,
            shortName: _club!.name,
            color1: _club!.color1,
            color2: _club!.color2,
            clubId: _club!.id,
          )
        : null;

    return Scaffold(
      key: ValueKey(_club?.id), // Force rebuild when club changes
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        key: ValueKey('appbar_${_club?.id}'), // Force appbar rebuild
        team: clubTeam,
        title: Text(
          _club?.name ?? 'ClubSync',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_club != null)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                NavigationHelper.navigateTo(
                    context, '/club/${_club!.id}/stats');
              },
              tooltip: 'Club Statistics',
            ),
          // Sign In/Out button
          StreamBuilder<User?>(
            stream: AuthService.instance.authStateChanges,
            builder: (context, snapshot) {
              final isSignedIn = snapshot.data != null;

              if (isSignedIn) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  tooltip: AuthService.instance.currentUserEmail ?? 'Account',
                  onSelected: (value) async {
                    if (value == 'signout') {
                      await AuthService.instance.signOut();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Signed out successfully')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthService.instance.currentUserEmail ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (AdminService.instance.isAdmin)
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return TextButton.icon(
                  onPressed: () {
                    if (!_isNavigatingToSignIn) {
                      _isNavigatingToSignIn = true;
                      NavigationHelper.navigateTo(context, '/signin');
                      // Reset flag after a delay
                      Future.delayed(const Duration(seconds: 2), () {
                        _isNavigatingToSignIn = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                );
              }
            },
          ),
          if (!kIsWeb && _isSubscribed)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.yellow),
              onPressed: () => _shareClub(),
            ),
          if (!kIsWeb)
            TextButton(
              onPressed: () async {
                if (!_isSubscribed) {
                  await SubscriptionService.instance.purchaseSubscription();
                  setState(() {});
                }
              },
              child: Text(
                _isSubscribed ? 'Pro' : 'Go Pro',
                style: const TextStyle(color: Colors.yellow),
              ),
            ),
          IconButton(
            onPressed: () {
              if (_club != null) {
                NavigationHelper.navigateTo(
                    context, '/club/${_club!.id}/settings');
              } else {
                NavigationHelper.navigateTo(context, '/settings');
              }
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton:
          _club != null && AdminService.instance.canManageClub(_club)
              ? FloatingActionButton(
                  onPressed: () => _showAddTeamDialog(),
                  child: const Icon(Icons.add),
                  tooltip: 'Add Team',
                )
              : null,
      body: FutureBuilder<bool>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (_club == null) {
            // No specific club loaded - show club selection
            return StreamBuilder<User?>(
              stream: AuthService.instance.authStateChanges,
              builder: (context, authSnapshot) {
                if (_allClubs.isNotEmpty) {
                  // Show club selection list
                  return _buildClubSelectionView();
                }

                // No clubs exist - show create option
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No Clubs Found',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      if (AdminService.instance.isAdmin)
                        ElevatedButton(
                          onPressed: () => _createClub(),
                          child: const Text('Create New Club'),
                        )
                      else
                        Column(
                          children: [
                            if (AuthService.instance.isSignedIn) ...[
                              const Text(
                                'Only administrators can create clubs.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Logged in as: ${AdminService.instance.currentUserEmail}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ] else ...[
                              const Text(
                                'Sign in to create or manage clubs.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (!_isNavigatingToSignIn) {
                                    _isNavigatingToSignIn = true;
                                    NavigationHelper.navigateTo(
                                        context, '/signin');
                                    // Reset flag after a delay
                                    Future.delayed(const Duration(seconds: 2),
                                        () {
                                      _isNavigatingToSignIn = false;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Sign In'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadTeams();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Club Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_club!.color1, _club!.color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (_club!.logoUrl != null)
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_club!.logoUrl!),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            _club!.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_club!.description != null)
                            Text(
                              _club!.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Club Stats Summary
                  if (_clubStats != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Club Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatColumn(
                                      'Teams', _teams.length.toString()),
                                  _buildStatColumn('Total Games',
                                      _clubStats!.totalGames.toString()),
                                  _buildStatColumn('Total Goals',
                                      _clubStats!.totalGoals.toString()),
                                  _buildStatColumn('Total Assists',
                                      _clubStats!.totalAssists.toString()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Teams Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Teams',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (AdminService.instance.canManageClub(_club))
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings),
                                onPressed: () => _manageClubAdmins(),
                                tooltip: 'Manage Admins',
                              ),
                            if (AdminService.instance.canManageClub(_club))
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editClub(),
                                tooltip: 'Edit Club',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_teams.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text(
                          'No teams yet. Tap + to add a team.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: kIsWeb ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        return _buildTeamCard(team);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTeamCard(Team team) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openTeam(team),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [team.color1, team.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (team.logoUrl != null)
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(team.logoUrl!),
                        backgroundColor: Colors.white,
                      )
                    else
                      const Icon(Icons.groups, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        team.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'remove') {
                      _removeTeamFromClub(team);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from Club'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubSelectionView() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Select a Club'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0 && AdminService.instance.isAdmin) {
                    // Create New Club button
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () => _createClub(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Club'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  }

                  final clubIndex =
                      AdminService.instance.isAdmin ? index - 1 : index;
                  if (clubIndex >= _allClubs.length) return null;

                  final club = _allClubs[clubIndex];
                  return _buildClubCard(club);
                },
                childCount:
                    _allClubs.length + (AdminService.instance.isAdmin ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectClub(club),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [club.color1, club.color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (club.logoUrl != null)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(club.logoUrl!),
                  backgroundColor: Colors.white,
                )
              else
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.groups, size: 40, color: Colors.blue),
                ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (club.description != null &&
                        club.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          club.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectClub(Club club) async {
    // Navigate to the club URL - this will trigger a rebuild with the club loaded
    NavigationHelper.navigateTo(context, '/club/${club.id}');
  }

  void _openTeam(Team team) {
    if (_club != null) {
      NavigationHelper.navigateTo(
          context, '/club/${_club!.id}/team/${team.id}');
    } else {
      NavigationHelper.navigateTo(context, '/team/${team.id}');
    }
  }

  Future<bool> _load() async {
    if (widget.clubId != null) {
      // Load specific club by ID
      final clubIdInt = int.tryParse(widget.clubId!);
      if (clubIdInt != null) {
        _club = await Club.fromId(clubIdInt);
        if (_club != null) {
          await _loadTeams();
        }
      }
    } else {
      // No clubId provided, load all clubs for selection
      _allClubs = await Club.all();
      // Don't auto-load a club, let admin select from list
    }
    return true;
  }

  Future<void> _loadTeams() async {
    if (_club == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _teams = await _club!.getTeams();
      _teams.sort((a, b) => a.fullName.compareTo(b.fullName));

      // Load club stats
      _clubStats = await ClubStats.fromClubId(_club!.id);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createClub() async {
    // Check admin access
    if (!AdminService.instance.isAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only administrators (${AdminService.adminEmails.join(", ")}) can create clubs.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String clubName = '';
    String clubDescription = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Club'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Club Name'),
                onChanged: (value) => clubName = value,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                onChanged: (value) => clubDescription = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (clubName.isNotEmpty) {
                  final clubId = DateTime.now().millisecondsSinceEpoch;
                  final currentUserId = AuthService.instance.currentUser?.uid;
                  final newClub = Club(
                    id: clubId,
                    name: clubName,
                    description:
                        clubDescription.isEmpty ? null : clubDescription,
                    createdAt: DateTime.now(),
                    createdBy: currentUserId, // Set creator as club admin
                    adminIds: currentUserId != null ? [currentUserId] : null,
                  );

                  // Insert club directly to root Clubs path (not subscription-based)
                  final clubKey = clubId.toString();
                  await FirebaseDatabase.instance
                      .ref('Clubs')
                      .child(clubKey)
                      .set(newClub.toMap());

                  setState(() {
                    _club = newClub;
                  });

                  Navigator.of(context).pop();

                  // Load teams for the new club
                  await _loadTeams();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _manageClubAdmins() async {
    if (_club == null) return;

    await showDialog(
      context: context,
      builder: (context) => AdminManagementDialog(club: _club),
    );

    // Reload club data to get updated admin list
    final updatedClub = await Club.fromId(_club!.id);
    if (updatedClub != null) {
      setState(() {
        _club = updatedClub;
      });
    }
  }

  Future<void> _editClub() async {
    if (_club == null) return;

    String clubName = _club!.name;
    String clubDescription = _club!.description ?? '';
    Color color1 = _club!.color1;
    Color color2 = _club!.color2;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Club'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(text: clubName),
                      decoration: const InputDecoration(labelText: 'Club Name'),
                      onChanged: (value) => clubName = value,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: clubDescription),
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      onChanged: (value) => clubDescription = value,
                    ),
                    const SizedBox(height: 20),
                    const Text('Primary Color'),
                    ColorPicker(
                      pickerColor: color1,
                      onColorChanged: (color) {
                        setDialogState(() => color1 = color);
                      },
                      pickerAreaHeightPercent: 0.3,
                    ),
                    const SizedBox(height: 10),
                    const Text('Secondary Color'),
                    ColorPicker(
                      pickerColor: color2,
                      onColorChanged: (color) {
                        setDialogState(() => color2 = color);
                      },
                      pickerAreaHeightPercent: 0.3,
                    ),
                    const SizedBox(height: 20),
                    if (!kIsWeb)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _updateClubLogo();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.photo),
                        label: const Text('Change Logo'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update club directly in Firebase
                    await FirebaseDatabase.instance
                        .ref(ClubSyncCollections.clubs)
                        .child(_club!.id.toString())
                        .update({
                      'name': clubName,
                      'description': clubDescription,
                      'color1': color1.toARGB32(),
                      'color2': color2.toARGB32(),
                    });

                    final updated = await Club.fromId(_club!.id);
                    setState(() {
                      _club = updated;
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateClubLogo() async {
    if (_club == null || kIsWeb) return;

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (_club!.logoUrl != null && _club!.logoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(_club!.logoUrl!).delete();
        } catch (e) {
          // Image may not exist
        }
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('club_images/${DateTime.now().toIso8601String()}');
      await storageRef.putFile(File(pickedFile.path));
      final imageUrl = await storageRef.getDownloadURL();

      await DatabaseService.instance.update(
        'Clubs',
        {'logoUrl': imageUrl},
        key: _club!.id.toString(),
      );

      final updated = await Club.fromId(_club!.id);
      setState(() {
        _club = updated;
      });
    }
  }

  Future<void> _showAddTeamDialog() async {
    if (_club == null) return;

    // Check if there are existing teams without a club
    final allTeams = await Team.all();
    final unassignedTeams = allTeams.where((t) => t.clubId == null).toList();

    if (unassignedTeams.isEmpty) {
      // Create new team
      await _createNewTeam();
    } else {
      // Show option to create new or assign existing
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Team'),
            content: const Text(
                'Would you like to create a new team or assign an existing team?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _assignExistingTeam(unassignedTeams);
                },
                child: const Text('Assign Existing'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _createNewTeam();
                },
                child: const Text('Create New'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _createNewTeam() async {
    if (_club == null) return;

    String teamName = '';
    String teamShortName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Team Name'),
                onChanged: (value) => teamName = value,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: 'Short Name'),
                onChanged: (value) => teamShortName = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (teamName.isNotEmpty && teamShortName.isNotEmpty) {
                  final teamId = DateTime.now().millisecondsSinceEpoch;
                  final teamData = {
                    'id': teamId,
                    'fullName': teamName,
                    'shortName': teamShortName,
                    'clubId': _club!.id,
                    'color1': _club!.color1.toARGB32(),
                    'color2': _club!.color2.toARGB32(),
                  };

                  // Insert directly into ClubTeams collection at root level
                  await FirebaseDatabase.instance
                      .ref(ClubSyncCollections.teams)
                      .child(teamId.toString())
                      .set(teamData);

                  await _loadTeams();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _assignExistingTeam(List<Team> unassignedTeams) async {
    if (_club == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Existing Team'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: unassignedTeams.length,
              itemBuilder: (context, index) {
                final team = unassignedTeams[index];
                return ListTile(
                  title: Text(team.fullName),
                  subtitle: Text(team.shortName),
                  onTap: () async {
                    // Update team in ClubTeams collection
                    await FirebaseDatabase.instance
                        .ref(ClubSyncCollections.teams)
                        .child(team.id.toString())
                        .update({'clubId': _club!.id});

                    await _loadTeams();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeTeamFromClub(Team team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Team'),
          content: Text(
              'Remove ${team.fullName} from this club? The team data will not be deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Remove team from club by setting clubId to null in ClubTeams collection
      await FirebaseDatabase.instance
          .ref(ClubSyncCollections.teams)
          .child(team.id.toString())
          .update({'clubId': null});

      await _loadTeams();
    }
  }

  Future<void> _shareClub() async {
    // TODO: Implement club sharing similar to team sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Club sharing coming soon!')),
    );
  }
}
