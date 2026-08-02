import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/widgets/common/skeleton_container.dart';
import 'package:team_sync/features/players/widgets/responsive_player_avatar.dart';

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
            return _buildSkeleton();
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
              child: ListView.separated(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
                  itemCount: widget.game.scoringEvents.length,
                  itemBuilder: (context, index) {
                    final event = widget.game.scoringEvents[index];
                    final assistEvent = assistEvents
                        .where((e) =>
                            (((e.id == event.id + 1) ||
                                    e.eventMinute == event.eventMinute) &&
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
                            ? Row(
                                children: [
                                  if (event.player != null &&
                                      event.player!.id != -2) ...[
                                    ResponsivePlayerAvatar(
                                        player: event.player!,
                                        avatarSize: 18,
                                        preferProfileImage: false,
                                        useLatestImages: true,
                                        season: widget.season),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: AutoSizeText(
                                        event.player?.displayName ?? '',
                                        minFontSize: 14),
                                  )
                                ],
                              )
                            : AutoSizeText(event.team.shortName,
                                minFontSize: 14),
                        subtitle: (assistEvent?.player != null &&
                                assistEvent!.player!.id != -2)
                            ? Row(
                                children: [
                                  AutoSizeText('Assisted by ', minFontSize: 14),
                                  ResponsivePlayerAvatar(
                                      player: assistEvent.player!,
                                      avatarSize: 18,
                                      preferProfileImage: false,
                                      useLatestImages: true,
                                      season: widget.season),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AutoSizeText(
                                        assistEvent.player!.displayName,
                                        minFontSize: 14),
                                  )
                                ],
                              )
                            : AutoSizeText(
                                event.team.id == widget.team.id &&
                                        event.eventType == 'PenaltyKick'
                                    ? 'PK'
                                    : event.team.id == widget.season.team.id
                                        ? (event.player == null ||
                                                event.player?.id == -2)
                                            ? 'Own goal by ${opponent.shortName}'
                                            : ''
                                        : '',
                                minFontSize: 14),
                        trailing: Text(
                            widget.game.getScore(widget.season.teamId,
                                minute: event.eventMinute),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)));
                  },
                  separatorBuilder: (context, index) {
                    return const Divider(height: 1);
                  }));
        });
  }

  Widget _buildSkeleton() {
    return Container(
      padding: const EdgeInsets.only(top: 5, left: 16, right: 16, bottom: 10),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3, // Show 3 dummy rows
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: SkeletonContainer.rectangular(
              width: 20,
              height: 14,
            ),
            title: Row(
              children: [
                SkeletonContainer.circular(
                  size: 18,
                ),
                const SizedBox(width: 8),
                SkeletonContainer.rectangular(
                  width: 120,
                  height: 14,
                ),
              ],
            ),
            trailing: SkeletonContainer.rectangular(
              width: 30,
              height: 14,
            ),
          );
        },
      ),
    );
  }
}
