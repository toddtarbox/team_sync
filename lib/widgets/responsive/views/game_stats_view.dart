import 'package:auto_size_text/auto_size_text.dart';
import 'package:change_case/change_case.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';

class GameStatsView extends StatefulWidget {
  final Season season;
  final Game game;
  final EventEmitter eventEmitter;

  const GameStatsView(
      {super.key,
      required this.season,
      required this.game,
      required this.eventEmitter});

  @override
  State<GameStatsView> createState() => _GameStatsViewState();
}

class _GameStatsViewState extends State<GameStatsView> {
  late Game _game;

  @override
  void initState() {
    _game = widget.game;

    widget.eventEmitter.on('eventCreated', context,
        (event, eventContext) async {
      await _loadStats();
      setState(() {});
    });

    widget.eventEmitter.on('advanceGame', context, (event, eventContext) async {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadStats(),
        builder: (BuildContext context, AsyncSnapshot<GameStats> snapshot) {
          if (snapshot.hasData) {
            final scoringEvents = _game.allGameEvents
                .where((e) =>
                    e.eventType == 'Shot' && e.eventData == 0 ||
                    (e.eventType == 'PenaltyKick' &&
                        e.eventData == 0 &&
                        e.eventMinute > 0))
                .toList(growable: false)
                .toList(growable: false);

            final assistEvents = _game.allGameEvents
                .where((e) => e.eventType == 'Assist')
                .toList(growable: false)
                .toList(growable: false);

            final stats = snapshot.data!;
            final statCategoryTiles = LeaderCategory.values.map((category) {
              return ListTile(
                title: Center(
                    child: Text(category.name.toSentenceCase().toTitleCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24))),
                leading: GestureDetector(
                    onTap: () async {
                      final playerStats = await stats.getStatPlayers(category);
                      if (playerStats.isNotEmpty) {
                        final sortedStats = List.from(playerStats.entries);
                        sortedStats.sort((a, b) => b.value.compareTo(a.value));

                        if (!mounted) return;
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ListView.builder(
                                  itemCount: sortedStats.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ListTile(
                                          title: Center(
                                              child: Text(
                                                  category.name
                                                      .toSentenceCase()
                                                      .toTitleCase(),
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold))));
                                    }

                                    final player = sortedStats[index - 1].key;
                                    final count = sortedStats[index - 1].value;
                                    return ListTile(
                                      leading: Text(player.displayName,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      title: Text(count.toString(),
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                    );
                                  });
                            });
                      }
                    },
                    child: Text(
                        _game.allGameEvents
                            .where((e) =>
                                e.eventType == category.name &&
                                e.team.id == widget.season.teamId)
                            .length
                            .toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            decoration: category.name != 'Corners' &&
                                    _game.allGameEvents
                                        .where((e) =>
                                            e.eventType == category.name &&
                                            e.team.id == widget.season.teamId)
                                        .isNotEmpty
                                ? TextDecoration.underline
                                : null))),
                trailing: Text(
                    _game.allGameEvents
                        .where((e) =>
                            e.eventType == category.name &&
                            e.team.id != widget.season.teamId)
                        .length
                        .toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 24)),
              );
            }).toList(growable: false);

            return ListView.separated(
                itemCount: scoringEvents.length + 2 + statCategoryTiles.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const ListTile(
                        title: Center(
                            child: Text('Scoring Summary',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))));
                  } else if (index <= scoringEvents.length) {
                    final event = scoringEvents[index - 1];
                    final assistEvent = assistEvents
                        .where((e) =>
                            (e.id == event.id + 1 && e.eventType == 'Assist') ||
                            e.eventData == event.id)
                        .firstOrNull;

                    final opponent =
                        !widget.game.isHomeTeam(widget.season.teamId)
                            ? widget.game.homeTeam
                            : widget.game.awayTeam;

                    return ListTile(
                        leading: AutoSizeText('${event.eventMinute}\'',
                            minFontSize: 14),
                        title: event.team.id == widget.season.team.id
                            ? AutoSizeText(event.player?.displayName ?? '',
                                minFontSize: 14)
                            : AutoSizeText(event.team.shortName,
                                minFontSize: 14),
                        subtitle: AutoSizeText(
                          event.team.id == widget.season.team.id &&
                                  assistEvent != null
                              ? assistEvent.display
                              : event.eventType == 'PenaltyKick'
                                  ? 'PK'
                                  : event.team.id == widget.season.team.id
                                      ? event.player == null
                                          ? 'Own goal by ${opponent.shortName}'
                                          : 'No assist'
                                      : '',
                        ),
                        trailing: Text(
                            maxLines: 1,
                            _game.getScore(widget.season.teamId,
                                minute: event.eventMinute),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)));
                  } else if (index == scoringEvents.length + 1) {
                    return const ListTile(
                        title: Center(
                            child: Text('Game Stats',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))));
                  } else {
                    return statCategoryTiles[index - scoringEvents.length - 2];
                  }
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading stats'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<GameStats> _loadStats() async {
    await _game.loadGameEvents();
    return await _game.getStats(widget.season.teamId);
  }
}
