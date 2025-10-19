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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.game.allGameEvents.isEmpty) {
      widget.game.loadGameEvents().then((value) => setState(() {
            _isLoading = false;
          }));
      ;
    } else {
      setState(() {
        _isLoading = false;
      });
    }

    final assistEvents = widget.game.allGameEvents
        .where((e) => e.eventType == 'Assist')
        .toList(growable: false)
        .toList(growable: false);

    return Container(
        padding: EdgeInsets.only(top: 5, left: 16, right: 16, bottom: 10),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: widget.game.scoringEvents.length * 75,
                child: ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
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
                          tileColor: Colors.black45,
                          titleTextStyle: const TextStyle(color: Colors.white),
                          leading: AutoSizeText('${event.eventMinute}\'',
                              style: const TextStyle(color: Colors.white),
                              minFontSize: 14),
                          title: event.team.id == widget.season.team.id
                              ? AutoSizeText(event.player?.displayName ?? '',
                                  style: const TextStyle(color: Colors.white),
                                  minFontSize: 14)
                              : AutoSizeText(event.team.shortName,
                                  style: const TextStyle(color: Colors.white),
                                  minFontSize: 14),
                          subtitle: AutoSizeText(
                              event.team.id == widget.team.id &&
                                      assistEvent != null
                                  ? assistEvent.display
                                  : event.eventType == 'PenaltyKick'
                                      ? 'PK'
                                      : event.team.id == widget.season.team.id
                                          ? event.player == null
                                              ? 'Own goal by ${opponent.shortName}'
                                              : 'No assist'
                                          : '',
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Text(
                              maxLines: 1,
                              widget.game.getScore(widget.season.teamId,
                                  minute: event.eventMinute),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)));
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(height: 1, color: Colors.black);
                    })));
  }
}
