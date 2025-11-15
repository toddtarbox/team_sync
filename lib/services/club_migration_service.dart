import 'package:flutter/material.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/admin_service.dart';
import 'package:team_sync/services/database_service.dart';

/// Utility class to migrate existing single-team databases to club structure
class ClubMigrationService {
  /// Checks if the current database has any clubs
  static Future<bool> hasClubs() async {
    try {
      final clubs = await DatabaseService.instance.query('Clubs');
      return clubs.isNotEmpty;
    } catch (e) {
      // Clubs table might not exist in older databases
      return false;
    }
  }

  /// Checks if there are any teams without a club assignment
  static Future<bool> hasUnassignedTeams() async {
    try {
      final teams = await Team.all();
      return teams.any((team) => team.clubId == null);
    } catch (e) {
      debugPrint('Error checking for unassigned teams: $e');
      return false;
    }
  }

  /// Creates a club from an existing team
  static Future<Club?> createClubFromTeam(Team team,
      {String? clubName, String? description}) async {
    // Check admin access
    if (!AdminService.instance.isAdmin) {
      debugPrint('Error: Only admins can create clubs');
      return null;
    }

    try {
      final clubId = DateTime.now().millisecondsSinceEpoch;
      final club = Club(
        id: clubId,
        name: clubName ?? '${team.fullName} Club',
        description: description,
        color1: team.color1,
        color2: team.color2,
        logoUrl: team.logoUrl,
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.insert('Clubs', club.toMap());

      // Update the team to belong to this club
      await DatabaseService.instance.update(
        'Teams',
        {'clubId': clubId},
        key: team.id.toString(),
      );

      return club;
    } catch (e) {
      debugPrint('Error creating club from team: $e');
      return null;
    }
  }

  /// Assigns multiple teams to a club
  static Future<bool> assignTeamsToClub(List<Team> teams, int clubId) async {
    try {
      for (final team in teams) {
        await DatabaseService.instance.update(
          'Teams',
          {'clubId': clubId},
          key: team.id.toString(),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error assigning teams to club: $e');
      return false;
    }
  }

  /// Shows a dialog to help users migrate to club structure
  static Future<void> showMigrationDialog(BuildContext context) async {
    // Only show for admins
    if (!AdminService.instance.isAdmin) {
      return;
    }

    final hasUnassigned = await hasUnassignedTeams();

    if (!hasUnassigned) {
      return;
    }

    final teams = await Team.all();
    final unassignedTeams = teams.where((t) => t.clubId == null).toList();

    if (unassignedTeams.isEmpty) {
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ClubSync Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have ${unassignedTeams.length} team(s) that can be organized into clubs.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Would you like to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('• Create a new club for your teams'),
            const Text('• Keep using individual team management'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _showCreateClubDialog(context, unassignedTeams);
            },
            child: const Text('Create Club'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showCreateClubDialog(
      BuildContext context, List<Team> unassignedTeams) async {
    String clubName = '';
    String clubDescription = '';
    final selectedTeams = <Team>[];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Club Name',
                    hintText: 'e.g., Springfield Soccer Club',
                  ),
                  onChanged: (value) => clubName = value,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of your club',
                  ),
                  onChanged: (value) => clubDescription = value,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select teams to include:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...unassignedTeams.map((team) => CheckboxListTile(
                      title: Text(team.fullName),
                      value: selectedTeams.contains(team),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedTeams.add(team);
                          } else {
                            selectedTeams.remove(team);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: clubName.isEmpty || selectedTeams.isEmpty
                  ? null
                  : () async {
                      final clubId = DateTime.now().millisecondsSinceEpoch;
                      final club = Club(
                        id: clubId,
                        name: clubName,
                        description:
                            clubDescription.isEmpty ? null : clubDescription,
                        createdAt: DateTime.now(),
                      );

                      await DatabaseService.instance
                          .insert('Clubs', club.toMap());
                      await assignTeamsToClub(selectedTeams, clubId);

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Club "${clubName}" created with ${selectedTeams.length} team(s)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
