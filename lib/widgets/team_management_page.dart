import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/team_management_service.dart';

class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  _TeamManagementPageState createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  List<Team> _teams = [];
  Map<int, int> _teamGameCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() => _isLoading = true);
    try {
      final teams = await Team.all();
      final allGames = await DatabaseService.instance.query('Games');

      final counts = <int, int>{};
      for (var team in teams) {
        counts[team.id] = 0;
      }

      for (var gameMap in allGames) {
        final homeTeamId = gameMap['homeTeamId'] as int?;
        final awayTeamId = gameMap['awayTeamId'] as int?;

        if (homeTeamId != null && counts.containsKey(homeTeamId)) {
          counts[homeTeamId] = counts[homeTeamId]! + 1;
        }
        if (awayTeamId != null && counts.containsKey(awayTeamId)) {
          counts[awayTeamId] = counts[awayTeamId]! + 1;
        }
      }

      // Sort teams alphabetically by full name
      teams.sort((a, b) => a.fullName.compareTo(b.fullName));
      setState(() {
        _teams = teams;
        _teamGameCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete(Team team) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text(
            'Are you sure you want to delete ${team.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TeamManagementService.instance.deleteTeam(team);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully.')),
          );
        }
        _loadTeams();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(Team team) async {
    final formKey = GlobalKey<FormState>();
    String newFullName = team.fullName;
    String newShortName = team.shortName;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Team Name'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: newFullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onSaved: (value) => newFullName = value!.trim(),
                ),
                TextFormField(
                  initialValue: newShortName,
                  decoration: const InputDecoration(labelText: 'Short Name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onSaved: (value) => newShortName = value!.trim(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await TeamManagementService.instance
            .updateTeamName(team, newFullName, newShortName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team updated successfully.')),
          );
        }
        _loadTeams();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showMergeDialog(Team sourceTeam) async {
    Team? selectedTargetTeam;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Merge Team'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Merge ${sourceTeam.fullName} into:'),
                  const SizedBox(height: 16),
                  DropdownButton<Team>(
                    isExpanded: true,
                    hint: const Text('Select target team'),
                    value: selectedTargetTeam,
                    items: _teams
                        .where((t) => t.id != sourceTeam.id)
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.fullName),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedTargetTeam = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Warning: This will move all games, players, events, and seasons to the chosen team and delete the original team. This cannot be undone.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedTargetTeam == null
                      ? null
                      : () => Navigator.pop(context, true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Merge',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedTargetTeam != null) {
      try {
        await TeamManagementService.instance
            .mergeTeam(sourceTeam, selectedTargetTeam!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team merged successfully.')),
          );
        }
        _loadTeams();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(child: Text('No teams found.'))
              : ListView.builder(
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    final gameCount = _teamGameCounts[team.id] ?? 0;
                    return ListTile(
                      title: Text(team.fullName),
                      subtitle:
                          Text('Short: ${team.shortName} • Games: $gameCount'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: 'Edit Name',
                            onPressed: () => _showEditDialog(team),
                          ),
                          IconButton(
                            icon: const Icon(Icons.merge_type,
                                color: Colors.orange),
                            tooltip: 'Merge Team',
                            onPressed: () => _showMergeDialog(team),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Team',
                            onPressed: () => _handleDelete(team),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
