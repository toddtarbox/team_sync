import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/player_merger_tool.dart';

/// Launcher widget for the Player Merger Tool that handles team selection
class PlayerMergerToolLauncher extends StatefulWidget {
  final Team? team;

  const PlayerMergerToolLauncher({
    super.key,
    this.team,
  });

  @override
  State<PlayerMergerToolLauncher> createState() =>
      _PlayerMergerToolLauncherState();
}

class _PlayerMergerToolLauncherState extends State<PlayerMergerToolLauncher> {
  Team? _selectedTeam;
  List<Team>? _teams;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.team != null) {
      _selectedTeam = widget.team;
      _launchTool();
    } else {
      _loadTeams();
    }
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await DatabaseService.instance.query('Teams');
      final teams = results.map((t) => Team.fromMap(t)).toList();
      teams.sort((a, b) => a.fullName.compareTo(b.fullName));

      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading teams: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _launchTool() {
    if (_selectedTeam == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerMergerTool(team: _selectedTeam!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Merge Duplicate Players'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_teams == null || _teams!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Merge Duplicate Players'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'No teams found',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Please create a team first.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Duplicate Players'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a team to merge duplicate players:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _teams!.length,
                itemBuilder: (context, index) {
                  final team = _teams![index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.sports_soccer,
                            color: Colors.blue.shade900),
                      ),
                      title: Text(team.fullName),
                      subtitle: Text(team.shortName),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        setState(() {
                          _selectedTeam = team;
                        });
                        _launchTool();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
