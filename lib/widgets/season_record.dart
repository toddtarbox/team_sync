import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

class SeasonRecord extends StatelessWidget {
  final List<Season> seasons;
  final bool singleSeason;
  final bool isOverall; // New parameter to make overall record bigger

  const SeasonRecord(this.seasons,
      {this.singleSeason = true, this.isOverall = false, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final games =
        seasons.map((s) => s.games).toList(growable: false).expand((i) => i);
    final team = seasons.first.team;
    final teamId = team.id;

    int wins = games.where((g) => g.isWin(teamId)).length;
    int losses = games
        .where((g) => g.gameStatus.index >= 9 && !g.isWin(teamId) && !g.isTie)
        .length;
    int ties = games.where((g) => g.isTie).length;

    // Calculate total games played (completed games only)
    int totalGamesPlayed = wins + losses + ties;

    // Calculate win percentage (only if games have been played)
    double? winPercentage;
    if (totalGamesPlayed > 0) {
      winPercentage = (wins / totalGamesPlayed) * 100;
    }

    final String leading = !singleSeason
        ? AppLocalizations.of(context)!.overall
        : AppLocalizations.of(context)!.season;

    final logoUrl = !singleSeason ? team.logoUrl : null;

    // Check screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450; // Phone screens in portrait

    return Container(
      width: (singleSeason || isOverall) ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal:
            isOverall ? (isSmallScreen ? 12 : 32) : (singleSeason ? 24 : 16),
        vertical:
            isOverall ? (isSmallScreen ? 12 : 24) : (singleSeason ? 20 : 12),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(isOverall ? 16 : 12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: isOverall ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize:
            (singleSeason || isOverall) ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (logoUrl != null && logoUrl.isNotEmpty) ...[
            GestureDetector(
              onDoubleTap: () {
                _showPhoto(context, logoUrl);
              },
              child: ResponsiveAvatar(
                size: isOverall ? (isSmallScreen ? 24 : 32) : null,
                imageUrl: logoUrl,
                initials: team.fullName[0],
              ),
            ),
            SizedBox(width: isOverall ? (isSmallScreen ? 8 : 16) : 12),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: (singleSeason || isOverall)
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      leading,
                      style: TextStyle(
                        fontSize: isOverall
                            ? (isSmallScreen ? 14 : 18)
                            : (singleSeason ? 14 : 12),
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Show win percentage next to label if games have been played
                    if (winPercentage != null) ...[
                      SizedBox(
                          width: isOverall
                              ? (isSmallScreen ? 6 : 12)
                              : (singleSeason ? 8 : 6)),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isOverall
                                ? (isSmallScreen ? 8 : 14)
                                : (singleSeason ? 10 : 6),
                            vertical: isOverall
                                ? (isSmallScreen ? 4 : 6)
                                : (singleSeason ? 4 : 3),
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(isOverall
                                ? (isSmallScreen ? 4 : 8)
                                : (singleSeason ? 6 : 4)),
                          ),
                          child: Text(
                            '${winPercentage.toStringAsFixed(1)}% win pct',
                            style: TextStyle(
                              fontSize: isOverall
                                  ? (isSmallScreen ? 11 : 16)
                                  : (singleSeason ? 12 : 10),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(
                    height: isOverall
                        ? (isSmallScreen ? 8 : 12)
                        : (singleSeason ? 8 : 4)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatBadge(
                      context,
                      wins.toString(),
                      loc.winAbbreviation,
                      Theme.of(context).colorScheme.primary,
                      isLarge: singleSeason,
                      isOverall: isOverall,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(
                        width: isOverall
                            ? (isSmallScreen ? 4 : 16)
                            : (singleSeason ? 12 : 8)),
                    _buildStatBadge(
                      context,
                      losses.toString(),
                      loc.lossAbbreviation,
                      Theme.of(context).colorScheme.error,
                      isLarge: singleSeason,
                      isOverall: isOverall,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(
                        width: isOverall
                            ? (isSmallScreen ? 4 : 16)
                            : (singleSeason ? 12 : 8)),
                    _buildStatBadge(
                      context,
                      ties.toString(),
                      loc.tieAbbreviation,
                      Theme.of(context).colorScheme.tertiary,
                      isLarge: singleSeason,
                      isOverall: isOverall,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(
      BuildContext context, String value, String label, Color color,
      {bool isLarge = false,
      bool isOverall = false,
      bool isSmallScreen = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isOverall ? (isSmallScreen ? 6 : 20) : (isLarge ? 16 : 8),
        vertical: isOverall ? (isSmallScreen ? 4 : 12) : (isLarge ? 8 : 4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(
            isOverall ? (isSmallScreen ? 4 : 10) : (isLarge ? 8 : 6)),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: isOverall ? (isSmallScreen ? 1 : 2) : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize:
                  isOverall ? (isSmallScreen ? 18 : 32) : (isLarge ? 24 : 16),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(
              width: isOverall ? (isSmallScreen ? 2 : 8) : (isLarge ? 6 : 4)),
          Text(
            label,
            style: TextStyle(
              fontSize:
                  isOverall ? (isSmallScreen ? 11 : 20) : (isLarge ? 16 : 12),
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhoto(BuildContext context, String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(logoUrl),
          ),
        );
      },
    );
  }
}
