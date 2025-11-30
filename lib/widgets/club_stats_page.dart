import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/club_stats.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class ClubStatsPage extends StatefulWidget {
  final Club club;

  const ClubStatsPage({super.key, required this.club});

  @override
  State<ClubStatsPage> createState() => _ClubStatsPageState();
}

class _ClubStatsPageState extends State<ClubStatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ClubStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _stats = await ClubStats.fromClubId(widget.club.id);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        title: Text('${widget.club.name} Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.leaders, icon: const Icon(Icons.star)),
            Tab(text: loc.teamStandings, icon: const Icon(Icons.leaderboard)),
            Tab(text: loc.overview, icon: const Icon(Icons.bar_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeadersTab(),
                _buildStandingsTab(),
                _buildOverviewTab(),
              ],
            ),
    );
  }

  Widget _buildLeadersTab() {
    final loc = AppLocalizations.of(context)!;
    if (_stats == null) {
      return Center(child: Text(loc.noDataAvailable));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Top Scorers',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<MapEntry<Player, int>>>(
            future: _stats!.getTopScorers(limit: 10),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return _buildLeadersList(snapshot.data!, 'Goals');
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Top Assists',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<MapEntry<Player, int>>>(
            future: _stats!.getTopAssists(limit: 10),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return _buildLeadersList(snapshot.data!, 'Assists');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeadersList(
      List<MapEntry<Player, int>> leaders, String statLabel) {
    final loc = AppLocalizations.of(context)!;
    if (leaders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(loc.noDataAvailable, style: const TextStyle(fontSize: 16)),
      );
    }

    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leaders.length,
        itemBuilder: (context, index) {
          final entry = leaders[index];
          final player = entry.key;
          final value = entry.value;

          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(player.displayName),
            subtitle: FutureBuilder<Team?>(
              future: Team.fromId(player.teamId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(snapshot.data!.fullName);
                }
                return const Text('...');
              },
            ),
            trailing: Text(
              '$value $statLabel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandingsTab() {
    final loc = AppLocalizations.of(context)!;
    if (_stats == null) {
      return Center(child: Text(loc.noDataAvailable));
    }

    final standings = _stats!.getTeamStandings();
    if (standings.isEmpty) {
      return Center(child: Text(loc.noTeamDataAvailable));
    }

    // Sort teams by points (wins * 3 + draws)
    final sortedTeams = standings.entries.toList()
      ..sort((a, b) => b.value['points']!.compareTo(a.value['points']!));

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Team Standings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: DataTable(
              columns: [
                DataColumn(label: Text(loc.team)),
                const DataColumn(label: Text('W')),
                const DataColumn(label: Text('D')),
                const DataColumn(label: Text('L')),
                const DataColumn(label: Text('GF')),
                const DataColumn(label: Text('GA')),
                const DataColumn(label: Text('Pts')),
              ],
              rows: sortedTeams.map((entry) {
                final teamId = entry.key;
                final stats = entry.value;

                return DataRow(cells: [
                  DataCell(
                    FutureBuilder<Team?>(
                      future: Team.fromId(teamId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(snapshot.data!.shortName);
                        }
                        return const Text('...');
                      },
                    ),
                  ),
                  DataCell(Text('${stats['wins']}')),
                  DataCell(Text('${stats['draws']}')),
                  DataCell(Text('${stats['losses']}')),
                  DataCell(Text('${stats['goalsFor']}')),
                  DataCell(Text('${stats['goalsAgainst']}')),
                  DataCell(
                    Text(
                      '${stats['points']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final loc = AppLocalizations.of(context)!;
    if (_stats == null) {
      return Center(child: Text(loc.noDataAvailable));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Club Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow('Total Games Played', '${_stats!.totalGames}'),
                  _buildStatRow('Total Goals Scored', '${_stats!.totalGoals}'),
                  _buildStatRow('Total Assists', '${_stats!.totalAssists}'),
                  const SizedBox(height: 20),
                  FutureBuilder<List<Team>>(
                    future: widget.club.getTeams(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return _buildStatRow(
                          'Number of Teams',
                          '${snapshot.data!.length}',
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<MapEntry<Player, int>>>(
                    future: _stats!.getTopScorers(limit: 1),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final top = snapshot.data!.first;
                        return ListTile(
                          leading: const Icon(Icons.sports_soccer),
                          title: const Text('Top Scorer'),
                          subtitle: Text(top.key.displayName),
                          trailing: Text('${top.value} goals'),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  FutureBuilder<List<MapEntry<Player, int>>>(
                    future: _stats!.getTopAssists(limit: 1),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final top = snapshot.data!.first;
                        return ListTile(
                          leading: const Icon(Icons.add_reaction),
                          title: const Text('Top Assist Provider'),
                          subtitle: Text(top.key.displayName),
                          trailing: Text('${top.value} assists'),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
