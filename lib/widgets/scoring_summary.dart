import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';

class ScoringSummary extends StatefulWidget {
  final Season season;
  final Team team;
  final Game game;

  const ScoringSummary(this.season, this.team, this.game, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _ScoringSummaryState();
  }
}

class _ScoringSummaryState extends State<ScoringSummary> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: widget.game.loadGameEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            debugPrintStack(stackTrace: snapshot.stackTrace);
            return const Center(child: Text('Error loading events'));
          }

          final assistEvents = widget.game.allGameEvents
              .where((e) => e.eventType == 'Assist')
              .toList(growable: false);

          return Container(
              padding: const EdgeInsets.only(
                  top: 5, left: 16, right: 16, bottom: 10),
              child: SizedBox(
                  height: widget.game.scoringEvents.length * 75,
                  child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.game.scoringEvents.length,
                      itemBuilder: (context, index) {
                        final event = widget.game.scoringEvents[index];
                        final assistEvent = assistEvents
                            .where((e) =>
                                (e.id == event.id + 1 &&
                                    e.eventType == 'Assist') ||
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
                              event.team.id == widget.team.id &&
                                      assistEvent != null
                                  ? assistEvent.display
                                  : event.eventType == 'PenaltyKick'
                                      ? 'PK'
                                      : event.team.id == widget.season.team.id
                                          ? (event.player == null ||
                                                  event.player?.id == -2)
                                              ? 'Own goal by ${opponent.shortName}'
                                              : 'No assist'
                                          : '',
                            ),
                            trailing: Text(
                                maxLines: 1,
                                widget.game.getScore(widget.season.teamId,
                                    minute: event.eventMinute),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)));
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(height: 1);
                      })));
        });
  }
}
