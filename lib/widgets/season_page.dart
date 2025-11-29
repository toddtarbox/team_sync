import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_award.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/models/team_award.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common/award_card.dart';
import 'package:team_sync/widgets/common/award_detail_dialog.dart';
import 'package:team_sync/widgets/common/tappable_image.dart';
import 'package:team_sync/widgets/game_result.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/scoring_summary.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/season_with_logo.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/video_thumbnail.dart';
import 'package:url_launcher/url_launcher.dart';

class SeasonPage extends StatefulWidget {
  final Season? season; // made nullable to support deep links

  const SeasonPage({super.key, this.season});

  @override
  State<SeasonPage> createState() => _SeasonPageState();
}

class _SeasonPageState extends State<SeasonPage> {
  final format = DateFormat('E MMM dd, yyyy');
  final saveFormat = DateFormat('MM.dd.yyyy');
  int _expandedGameId = 0;
  Future<Season>? _seasonFuture;
  Timer? _seasonLoadTimer;
  bool _seasonLoadTimedOut = false;

  // New: controllers for awards carousel on web
  final CarouselSliderController _teamAwardsController =
      CarouselSliderController();
  final CarouselSliderController _playerAwardsController =
      CarouselSliderController();
  bool _awardsExpanded = true; // Default to expanded
  int _teamCurrentPage = 0;
  int _playerCurrentPage = 0;
  // Cache the awards future to prevent rebuilding on setState
  final Map<int, Future<List<dynamic>>> _awardsFutureCache = {};

  // Helper to get path segments that works with hash-based routing used by go_router on web.
  List<String> _getPathSegments() {
    final uri = Uri.base;
    if (uri.fragment.isNotEmpty) {
      // Fragment may contain a path like '/team/123/season/45'
      try {
        final fragUri = Uri.parse(uri.fragment);
        if (fragUri.pathSegments.isNotEmpty) {
          return fragUri.pathSegments;
        }
      } catch (e) {
        // ignore and fall back to pathSegments
      }
    }
    return uri.pathSegments;
  }

  @override
  void initState() {
    super.initState();
    _loadAwardsExpansionState();
  }

  Future<void> _loadAwardsExpansionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expanded = prefs.getBool('awards_expanded') ?? true; // Default true
      if (mounted) {
        setState(() {
          _awardsExpanded = expanded;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _saveAwardsExpansionState(bool expanded) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('awards_expanded', expanded);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the season future once so FutureBuilder doesn't restart it
    if (_seasonFuture == null) {
      if (widget.season != null) {
        _seasonFuture = widget.season!.load().then((_) => widget.season!);
      } else {
        _startSeasonLoad();
      }
    }
  }

  void _startSeasonLoad() {
    _seasonLoadTimedOut = false;
    _seasonFuture = _loadSeason(context).timeout(const Duration(seconds: 20),
        onTimeout: () => throw Exception('Season load timed out'));

    // Start a short UI-only timer to show retry after 12s
    _seasonLoadTimer?.cancel();
    _seasonLoadTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) {
        setState(() {
          _seasonLoadTimedOut = true;
        });
      }
    });

    // When the future completes, cancel the timer and clear timeout flag
    _seasonFuture!.then((_) {
      _seasonLoadTimer?.cancel();
      if (mounted) setState(() => _seasonLoadTimedOut = false);
    }).catchError((_) {
      _seasonLoadTimer?.cancel();
    });
  }

  void _retrySeasonLoad() {
    setState(() {
      _seasonLoadTimedOut = false;
      _startSeasonLoad();
    });
  }

  String _getDatabaseId(BuildContext context) {
    return DatabaseService.instance.publicShareId!;
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the season using FutureBuilder so deep links without a provided
    // Season object render correctly. The entire scaffold depends on the
    // resolved season, so construct it inside the FutureBuilder.
    return FutureBuilder<Season>(
      future: _seasonFuture,
      builder: (BuildContext context, AsyncSnapshot<Season> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final season = snapshot.data!;
          final games = season.games;

          if (games.isEmpty) {
            // Show scaffold with app bar so deep-linked pages still show the header
            return Scaffold(
              appBar: buildStandardAppBar(
                  context: context,
                  team: season.team,
                  title: Text(season.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  actions: [
                    IconButton(
                        onPressed: () {
                          final databaseId = _getDatabaseId(context);
                          NavigationHelper.navigateTo(context,
                              '/team/$databaseId/season/${season.id}/players');
                        },
                        icon: const Icon(Icons.person_sharp)),
                    IconButton(
                        onPressed: () {
                          final databaseId = _getDatabaseId(context);
                          NavigationHelper.navigateTo(context,
                              '/team/$databaseId/season/${season.id}/stats');
                        },
                        icon: const Icon(Icons.paste_sharp)),
                  ]),
              floatingActionButton: kIsWeb
                  ? null
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [season.team.color1, season.team.color2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: FloatingActionButton(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: const Icon(Icons.add),
                          onPressed: () {
                            _showGame(season: season);
                          })),
              body: Column(
                children: [
                  Breadcrumbs(
                    items: buildTeamBreadcrumbs(
                      databaseId: DatabaseService.instance.publicShareId ?? '',
                      teamName: season.team.fullName,
                      seasonName: season.name,
                      seasonId: season.id,
                    ),
                  ),
                  SeasonWithLogo(season: season),
                  Expanded(
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(AppLocalizations.of(context)!.noGamesFound,
                              style: const TextStyle(fontSize: 24)),
                          GestureDetector(
                              onTap: () {
                                _showGame(season: season);
                              },
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .createNewGameToStart,
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.blue))),
                        ])),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
              appBar: buildStandardAppBar(
                  context: context,
                  team: season.team,
                  title: Text(season.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  actions: [
                    IconButton(
                        onPressed: () {
                          final databaseId = _getDatabaseId(context);
                          NavigationHelper.navigateTo(context,
                              '/team/$databaseId/season/${season.id}/players');
                        },
                        icon: const Icon(Icons.person_sharp)),
                    IconButton(
                        onPressed: () {
                          final databaseId = _getDatabaseId(context);
                          NavigationHelper.navigateTo(context,
                              '/team/$databaseId/season/${season.id}/stats');
                        },
                        icon: const Icon(Icons.paste_sharp)),
                  ]),
              floatingActionButton: kIsWeb
                  ? null
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [season.team.color1, season.team.color2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: FloatingActionButton(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          child: const Icon(Icons.add),
                          onPressed: () {
                            _showGame(season: season);
                          })),
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Breadcrumbs(
                          items: buildTeamBreadcrumbs(
                            databaseId:
                                DatabaseService.instance.publicShareId ?? '',
                            teamName: season.team.fullName,
                            seasonName: season.name,
                            seasonId: season.id,
                          ),
                        ),
                        SeasonWithLogo(season: season),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(25),
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                          child: Container(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(child: SeasonRecord([season])),
                            ),
                          ),
                        ),
                        // Awards Section
                        _buildAwardsSection(season),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(10),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final game = games[index];

                          final linkWidget = game.gameLinks?.isNotEmpty ?? false
                              ? GestureDetector(
                                  onTap: () async {
                                    await _launchUrl(game.gameLinks!);
                                  },
                                  child: VideoThumbnail(game.gameLinks!,
                                      width: 40, height: 28),
                                )
                              : const SizedBox(width: 24);

                          final gameCard = Container(
                            padding: const EdgeInsets.all(5),
                            child: Stack(
                              children: [
                                Card(
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                            game.displayName(season.teamId),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        subtitle:
                                            Text(format.format(game.date)),
                                        leading: linkWidget,
                                        trailing: Container(
                                          margin:
                                              const EdgeInsets.only(top: 20),
                                          child: IconButton(
                                            icon: Icon(
                                                game.id == _expandedGameId
                                                    ? Icons.expand_less
                                                    : Icons.expand_more),
                                            onPressed: () async {
                                              setState(() {
                                                _expandedGameId =
                                                    game.id == _expandedGameId
                                                        ? 0
                                                        : game.id;
                                              });
                                            },
                                          ),
                                        ),
                                        onTap: () {
                                          if (!kIsWeb) {
                                            _showGame(
                                                game: game, season: season);
                                          } else {
                                            _goToGame(game, season);
                                          }
                                        },
                                      ),
                                      if (game.id == _expandedGameId)
                                        ScoringSummary(
                                            season, season.team, game),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GameResult(game, season.teamId),
                                ),
                              ],
                            ),
                          );

                          if (kIsWeb) return gameCard;

                          return Dismissible(
                            key: Key(game.id.toString()),
                            direction: DismissDirection.startToEnd,
                            dismissThresholds: const {
                              DismissDirection.startToEnd: 0.5,
                            },
                            background: Container(color: Colors.red),
                            confirmDismiss: (_) {
                              return showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .confirmDelete),
                                    content: Text(AppLocalizations.of(context)!
                                        .areYouSureYouWantToDeleteThisGame),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .continueButton),
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancelButton),
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) async {
                              final candidates = await DatabaseService.instance
                                  .query('Games',
                                      orderByChild: 'id', equalTo: game.id);
                              for (final c in candidates) {
                                final k = c['_key']?.toString();
                                if (k != null) {
                                  await DatabaseService.instance
                                      .delete('Games', key: k);
                                }
                              }
                              setState(() {});
                            },
                            child: gameCard,
                          );
                        },
                        childCount: games.length,
                      ),
                    ),
                  ),
                ],
              ));
        } else if (snapshot.hasError) {
          // Show detailed error in debug mode so it's visible when deep-linking fails.
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error loading season:'),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString(),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _retrySeasonLoad,
                          child: const Text('Retry'))
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          // Still waiting: show spinner normally, but if we've timed out, show retry UI
          if (_seasonLoadTimedOut) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Taking too long to load season.'),
                const SizedBox(height: 8),
                ElevatedButton(
                    onPressed: _retrySeasonLoad, child: const Text('Retry'))
              ],
            ));
          }
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    _seasonLoadTimer?.cancel();
    // CarouselSlider controllers don't need disposal
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final urls = url.split(',');
    if (urls.length == 1) {
      await launchUrl(Uri.parse(url));
    } else {
      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Which Link"),
              content: DropdownMenu(
                  dropdownMenuEntries: urls
                      .map((url) =>
                          DropdownMenuEntry<String>(value: url, label: url))
                      .toList(growable: false),
                  onSelected: (url) {
                    _launchUrl(url!);
                  }),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
              ],
            );
          });
    }
  }

  Future<Season> _loadSeason(BuildContext context) async {
    // If season was provided, just load it
    if (widget.season != null) {
      await widget.season!.load();
      return widget.season!;
    }

    // Try to extract seasonId from the current URL path (e.g. /team/:db/season/:seasonId)
    try {
      // Ensure the database is opened for the shared database id in the URL
      try {
        final segmentsForDb = _getPathSegments();
        final teamIndex = segmentsForDb.indexOf('team');
        if (teamIndex != -1 && teamIndex + 1 < segmentsForDb.length) {
          final dbId = segmentsForDb[teamIndex + 1];
          if (DatabaseService.instance.publicShareId == null ||
              DatabaseService.instance.publicShareId != dbId) {
            // try opening the shared DB but don't block forever
            try {
              final opened = await DatabaseService.instance
                  .openFromId(dbId)
                  .timeout(const Duration(seconds: 10));
              if (!opened) {
                throw Exception('Failed to open shared database: $dbId');
              }
            } catch (te) {
              rethrow;
            }
          }
        }
      } catch (e) {
        rethrow;
      }
      final segments = _getPathSegments();
      final seasonIndex = segments.indexOf('season');
      if (seasonIndex == -1 || seasonIndex + 1 >= segments.length) {
        throw Exception('Season id not found in URL');
      }

      final seasonIdString = segments[seasonIndex + 1];
      final seasonId = int.parse(seasonIdString);

      List<Map<String, dynamic>> results;
      try {
        results = await DatabaseService.instance
            .query('Seasons', orderByChild: 'id', equalTo: seasonId)
            .timeout(const Duration(seconds: 10));
      } catch (te) {
        rethrow;
      }

      if (results.isEmpty) {
        throw Exception('Season not found: $seasonId');
      }

      final season = Season.fromMap(results.first);
      await season.load();
      return season;
    } catch (e) {
      rethrow;
    }
  }

  void _showGame({Game? game, Season? season}) {
    final s = season ?? widget.season!;
    final entries = s.teams
        .map((t) => DropdownMenuEntry<int>(value: t.id, label: t.fullName))
        .where((e) => e.value != s.teamId)
        .toList(growable: false);

    final isHomeTeam = game == null || game.isHomeTeam(s.teamId);

    final team = s.team;

    final homeTeam = game != null ? game.homeTeam : team;
    final awayTeam = game != null ? game.awayTeam : team;
    game ??=
        Game.initial(seasonId: s.id, homeTeam: homeTeam, awayTeam: awayTeam);

    int? location = isHomeTeam ? 0 : 1;
    bool canSave = game.gameStatus.index == 0;

    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      Text(
                        AppLocalizations.of(context)!.editGame,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(height: 20),
                      Row(children: [
                        Expanded(
                            child: RadioListTile(
                          title: Text(AppLocalizations.of(context)!.home,
                              style: const TextStyle(fontSize: 20)),
                          value: 0,
                          groupValue: location,
                          onChanged: (i) {
                            if (game!.gameStatus.index == 0) {
                              final tempTeam = game.homeTeam;
                              game.homeTeam = game.awayTeam;
                              game.awayTeam = tempTeam;

                              setModalState(() {
                                location = i;
                              });
                            }
                          },
                        )),
                        Expanded(
                            child: RadioListTile(
                          title: Text(AppLocalizations.of(context)!.away,
                              style: const TextStyle(fontSize: 20)),
                          value: 1,
                          groupValue: location,
                          onChanged: (i) {
                            if (game!.gameStatus.index == 0) {
                              final tempTeam = game.homeTeam;
                              game.homeTeam = game.awayTeam;
                              game.awayTeam = tempTeam;

                              setModalState(() {
                                location = i;
                              });
                            }
                          },
                        )),
                      ]),
                      const SizedBox(height: 30),
                      TextButton(
                          onPressed: () {
                            _createOpponent(s);
                          },
                          child: Text(
                              AppLocalizations.of(context)!.createNewOpponent)),
                      const SizedBox(height: 30),
                      DropdownMenu(
                          enabled: game!.gameStatus.index == 0,
                          initialSelection:
                              isHomeTeam ? game.awayTeam.id : game.homeTeam.id,
                          onSelected: (teamId) async {
                            if (location == 0) {
                              game!.awayTeam = await Team.fromId(teamId!);
                            } else {
                              game!.homeTeam = await Team.fromId(teamId!);
                            }

                            setModalState(() {
                              canSave = true;
                            });
                          },
                          width: double.infinity,
                          label: Text(
                              AppLocalizations.of(context)!.selectOpponent),
                          dropdownMenuEntries: entries),
                      const SizedBox(height: 30),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          onPressed: game.gameStatus.index == 0
                              ? () async {
                                  final date = await showDatePicker(
                                      context: context,
                                      initialDate: game!.date,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)));
                                  if (date != null) {
                                    setModalState(() {
                                      game!.date = date;
                                    });
                                  }
                                }
                              : null,
                          child: SizedBox(
                              width: 200,
                              child: Center(
                                  child: Text(format.format(game.date),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20))))),
                      const SizedBox(height: 30),
                      const Divider(),
                      TextFormField(
                          initialValue: game.description,
                          decoration: InputDecoration(
                              labelText: 'Description (optional)'),
                          onChanged: (name) => game!.description = name),
                      const SizedBox(height: 30),
                      TextFormField(
                          initialValue: game.gameLinks,
                          decoration:
                              InputDecoration(labelText: 'Links (optional)'),
                          onChanged: (links) => game!.gameLinks = links),
                      const SizedBox(height: 30),
                      const Divider(),
                      ScoreboardWidget(
                          compact: true,
                          game: game,
                          season: season,
                          teamId: season!.team.id),
                      const Divider(),
                      const SizedBox(height: 30),
                      game.id != -1
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text(
                                  AppLocalizations.of(context)!.goToGame,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _goToGame(game!, s);
                                await _loadSeason(context);
                              })
                          : Container(),
                      const SizedBox(height: 30),
                      Row(
                          mainAxisAlignment: canSave
                              ? MainAxisAlignment.spaceEvenly
                              : MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                                onTap: () async {
                                  await game!.saveGame();

                                  if (mounted) {
                                    Navigator.pop(context);
                                    setState(() {});
                                  }
                                },
                                child: Text(AppLocalizations.of(context)!.save,
                                    style: const TextStyle(fontSize: 20))),
                            const SizedBox(width: 30),
                            GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.cancelButton,
                                    style: const TextStyle(fontSize: 20)))
                          ])
                    ])));
          });
        });
  }

  Future<void> _goToGame(Game game, Season season) async {
    final databaseId = DatabaseService.instance.publicShareId;
    if (databaseId == null) return;

    // Use NavigationHelper for platform-appropriate navigation
    NavigationHelper.navigateTo(
      context,
      '/team/$databaseId/season/${season.id}/game/${game.id}',
      extra: {'season': season, 'game': game},
    );
  }

  void _createOpponent(Season season) {
    late String teamName;
    late String teamShortName;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    Text(AppLocalizations.of(context)!.newTeam),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.teamName),
                        onChanged: (name) => teamName = name),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.teamShortName),
                        onChanged: (name) => teamShortName = name),
                    const Spacer(),
                    TextButton(
                        onPressed: () {},
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                  child: Text(
                                      AppLocalizations.of(context)!.save,
                                      style: const TextStyle(fontSize: 20)),
                                  onTap: () async {
                                    if (teamName.isNotEmpty &&
                                        teamShortName.isNotEmpty) {
                                      Navigator.pop(context);
                                      await _saveTeam(teamName, teamShortName);
                                      await _loadSeason(context);
                                      Navigator.pop(context);
                                      _showGame(season: season);
                                    }
                                  }),
                              GestureDetector(
                                  child: Text(
                                      AppLocalizations.of(context)!
                                          .cancelButton,
                                      style: const TextStyle(fontSize: 20)),
                                  onTap: () {
                                    Navigator.pop(context);
                                  })
                            ]))
                  ])));
        });
  }

  Future<void> _saveTeam(String teamName, String teamShortName,
      {Color color1 = Colors.transparent,
      Color color2 = Colors.transparent}) async {
    await DatabaseService.instance.insert('Teams', {
      'id': DateTime.now().millisecondsSinceEpoch,
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1.toARGB32(),
      'color2': color2.toARGB32()
    });
  }

  Widget _buildAwardsSection(Season season) {
    final loc = AppLocalizations.of(context)!;

    // Cache the future so it doesn't rebuild when setState is called
    _awardsFutureCache[season.id] ??= Future.wait([
      _loadPlayerAwards(season.id),
      _loadTeamAwards(season.id),
    ]);

    return FutureBuilder<List<dynamic>>(
      future: _awardsFutureCache[season.id],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading awards: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final playerAwards =
            (snapshot.data?[0] as List<Map<String, dynamic>>?) ?? [];
        final teamAwards = (snapshot.data?[1] as List<TeamAward>?) ?? [];

        // On mobile, always show the section (even if empty) so coaches can add awards
        // On web, hide if empty
        if (kIsWeb && playerAwards.isEmpty && teamAwards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          elevation: 4,
          child: ExpansionTile(
            initiallyExpanded: _awardsExpanded,
            // Auto-play is handled by CarouselSlider based on _awardsExpanded state
            onExpansionChanged: (expanded) {
              _saveAwardsExpansionState(expanded); // Persist the state
              setState(() {
                _awardsExpanded = expanded;
              });
            },
            leading:
                const Icon(Icons.emoji_events, size: 28, color: Colors.amber),
            title: Text(
              loc.awards,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              // Awards Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Awards Section
                    if (!kIsWeb || teamAwards.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Team Awards',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          // Add button (mobile only)
                          if (!kIsWeb) ...[
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _showAddTeamAwardDialog(season),
                              tooltip: 'Add Team Award',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (teamAwards.isNotEmpty)
                        if (kIsWeb)
                          // Carousel layout for web (autoplays when expanded)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Height tuned to approximate the grid card size
                              final height =
                                  constraints.maxWidth > 800 ? 360.0 : 180.0;
                              return Column(
                                children: [
                                  CarouselSlider.builder(
                                    carouselController: _teamAwardsController,
                                    itemCount: teamAwards.length,
                                    options: CarouselOptions(
                                      height: height,
                                      viewportFraction: 0.35,
                                      enlargeCenterPage: true,
                                      enlargeFactor: 0.2,
                                      autoPlay: _awardsExpanded,
                                      autoPlayInterval:
                                          const Duration(seconds: 4),
                                      autoPlayAnimationDuration:
                                          const Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      pauseAutoPlayOnTouch: true,
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _teamCurrentPage = index;
                                        });
                                      },
                                    ),
                                    itemBuilder: (context, index, realIndex) {
                                      final isActive =
                                          index == _teamCurrentPage;
                                      return AnimatedScale(
                                        scale: isActive ? 1.0 : 0.95,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          decoration: isActive
                                              ? BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 12,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          child: _buildTeamAwardGridCard(
                                              teamAwards[index], season),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          // List layout for mobile
                          Column(
                            children: teamAwards
                                .map((award) =>
                                    _buildTeamAwardCard(award, season))
                                .toList(),
                          ),
                      if (teamAwards.isEmpty && !kIsWeb)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No team awards yet. Tap + to add one!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (playerAwards.isNotEmpty) const Divider(height: 24),
                    ],

                    // Player Awards Section
                    if (!kIsWeb || playerAwards.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.person, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Player Awards',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          if (!kIsWeb) ...[
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () =>
                                  _showAddPlayerAwardDialog(season),
                              tooltip: 'Add Player Award',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (playerAwards.isNotEmpty)
                        if (kIsWeb)
                          // Carousel layout for web (autoplays when expanded)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final height =
                                  constraints.maxWidth > 800 ? 360.0 : 180.0;
                              return Column(
                                children: [
                                  CarouselSlider.builder(
                                    carouselController: _playerAwardsController,
                                    itemCount: playerAwards.length,
                                    options: CarouselOptions(
                                      height: height,
                                      viewportFraction: 0.35,
                                      enlargeCenterPage: true,
                                      enlargeFactor: 0.2,
                                      autoPlay: _awardsExpanded,
                                      autoPlayInterval:
                                          const Duration(seconds: 4),
                                      autoPlayAnimationDuration:
                                          const Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      pauseAutoPlayOnTouch: true,
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _playerCurrentPage = index;
                                        });
                                      },
                                    ),
                                    itemBuilder: (context, index, realIndex) {
                                      final awardData = playerAwards[index];
                                      final isActive =
                                          index == _playerCurrentPage;
                                      return AnimatedScale(
                                        scale: isActive ? 1.0 : 0.95,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          decoration: isActive
                                              ? BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 12,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          child: _buildPlayerAwardGridCard(
                                            awardData['award'] as PlayerAward,
                                            awardData['player'] as Player,
                                            season,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        else
                          // List layout for mobile
                          Column(
                            children: playerAwards
                                .map((awardData) => _buildPlayerAwardCard(
                                      awardData['award'] as PlayerAward,
                                      awardData['player'] as Player,
                                      season,
                                    ))
                                .toList(),
                          ),
                      if (playerAwards.isEmpty && !kIsWeb)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'No player awards yet. Tap + to add one!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPlayerAwards(int seasonId) async {
    try {
      // Get all player awards for this season
      final results = await DatabaseService.instance
          .query('PlayerAwards', orderByChild: 'seasonId', equalTo: seasonId);

      final List<Map<String, dynamic>> awardWithPlayers = [];

      for (var result in results) {
        final award = PlayerAward.fromMap(result);
        // Load the player for this award
        final player =
            await Player.singleFromIdSeasonId(award.playerId, seasonId);
        if (player != null) {
          awardWithPlayers.add({
            'award': award,
            'player': player,
          });
        }
      }

      // Sort by player name
      awardWithPlayers.sort((a, b) => (a['player'] as Player)
          .displayName
          .compareTo((b['player'] as Player).displayName));

      return awardWithPlayers;
    } catch (e) {
      print('Error loading player awards: $e');
      return [];
    }
  }

  Future<List<TeamAward>> _loadTeamAwards(int seasonId) async {
    try {
      return await TeamAward.listFromSeasonId(seasonId);
    } catch (e) {
      print('Error loading team awards: $e');
      return [];
    }
  }

  Widget _buildTeamAwardCard(TeamAward award, Season season) {
    return AwardCard(
      title: award.title,
      description: award.description,
      imageUrl: award.imageUrl,
      variant: AwardCardVariant.list,
      iconColor: Colors.amber,
      isWeb: kIsWeb,
      onTap: () => _showTeamAwardDetailsDialog(award),
      onEdit:
          !kIsWeb ? () => _showAddTeamAwardDialog(season, award: award) : null,
      onDelete: !kIsWeb ? () => _deleteTeamAward(award) : null,
      onPromote: !kIsWeb ? () => _promoteAwardToAccomplishment(award) : null,
    );
  }

  Widget _buildTeamAwardGridCard(TeamAward award, Season season) {
    return AwardCard(
      title: award.title,
      description: award.description,
      imageUrl: award.imageUrl,
      variant: AwardCardVariant.grid,
      heroTag: 'team_award_${award.id}',
      iconColor: Colors.amber,
      onTap: () => _showTeamAwardDetailsDialog(award),
    );
  }

  Widget _buildPlayerAwardCard(
      PlayerAward award, Player player, Season season) {
    final awardImageUrl = (award.imageUrl != null && award.imageUrl!.isNotEmpty)
        ? award.imageUrl
        : (player.profileImage != null && player.profileImage!.isNotEmpty)
            ? player.profileImage
            : player.actionPhoto;

    return AwardCard(
      title: award.title,
      description: player.displayName,
      imageUrl: awardImageUrl,
      variant: AwardCardVariant.list,
      iconColor: Colors.grey,
      customIcon: Icons.person,
      onTap: () {
        final databaseId = DatabaseService.instance.publicShareId;
        if (databaseId != null) {
          NavigationHelper.navigateTo(
            context,
            '/team/$databaseId/season/${season.id}/players/${player.id}',
          );
        }
      },
    );
  }

  Widget _buildPlayerAwardGridCard(
      PlayerAward award, Player player, Season season) {
    final awardImageUrl = (award.imageUrl != null && award.imageUrl!.isNotEmpty)
        ? award.imageUrl
        : (player.profileImage != null && player.profileImage!.isNotEmpty)
            ? player.profileImage
            : player.actionPhoto;

    return AwardCard(
      title: award.title,
      description: player.displayName,
      imageUrl: awardImageUrl,
      variant: AwardCardVariant.grid,
      heroTag: 'player_award_${award.id}_${player.id}',
      iconColor: Colors.grey,
      customIcon: Icons.person,
      onTap: () => _showPlayerAwardDetailsDialog(award, player),
    );
  }

  void _showAddTeamAwardDialog(Season season, {TeamAward? award}) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = award != null;
    final titleController = TextEditingController(text: award?.title ?? '');
    final descriptionController =
        TextEditingController(text: award?.description ?? '');
    final urlController = TextEditingController(text: award?.url ?? '');
    String? imageUrl = award?.imageUrl;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Team Award' : 'Add Team Award'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Award Title *',
                    hintText: 'e.g., Tournament Champions, League Winners',
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional details',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Optional link (e.g., article, photo)',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                // Image upload section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Award Image',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TappableImage.network(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                              heroTag: 'team_award_edit_preview',
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  imageUrl = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: isUploadingImage || kIsWeb
                            ? null
                            : () async {
                                setState(() {
                                  isUploadingImage = true;
                                });
                                try {
                                  final pickedFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    // Upload to Firebase Storage
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'award_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    await storageRef
                                        .putFile(File(pickedFile.path));
                                    final downloadUrl =
                                        await storageRef.getDownloadURL();
                                    setState(() {
                                      imageUrl = downloadUrl;
                                      isUploadingImage = false;
                                    });
                                  } else {
                                    setState(() {
                                      isUploadingImage = false;
                                    });
                                  }
                                } catch (e) {
                                  setState(() {
                                    isUploadingImage = false;
                                  });
                                  if (context.mounted) {
                                    String errorMessage =
                                        'Error uploading image';
                                    if (e
                                            .toString()
                                            .contains('not authorized') ||
                                        e.toString().contains('permission') ||
                                        e.toString().contains('unauthorized')) {
                                      errorMessage =
                                          'Not authorized to upload images. Please sign in on mobile to add images.';
                                    } else {
                                      errorMessage =
                                          'Error uploading image: ${e.toString()}';
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image),
                        label: Text(
                          isUploadingImage
                              ? 'Uploading...'
                              : kIsWeb
                                  ? 'Image upload requires mobile app'
                                  : 'Pick Image',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: isUploadingImage
                  ? null
                  : () {
                      final title = titleController.text.trim();

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Award title is required'),
                          ),
                        );
                        return;
                      }

                      _saveTeamAward(
                        season: season,
                        id: award?.id ?? DateTime.now().millisecondsSinceEpoch,
                        title: title,
                        description: descriptionController.text.trim(),
                        url: urlController.text.trim(),
                        imageUrl: imageUrl,
                      );

                      Navigator.pop(context);
                    },
              child: Text(isEdit ? loc.updateButton : loc.addButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTeamAward({
    required Season season,
    required int id,
    required String title,
    String? description,
    String? url,
    String? imageUrl,
  }) async {
    try {
      final award = TeamAward(
        id: id,
        teamId: season.teamId,
        seasonId: season.id,
        title: title,
        description: description?.isEmpty == true ? null : description,
        imageUrl: imageUrl?.isEmpty == true ? null : imageUrl,
        url: url?.isEmpty == true ? null : url,
      );

      await award.save();

      if (mounted) {
        setState(() {
          // Clear cache to force reload of awards
          _awardsFutureCache.remove(season.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team award saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving team award: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _promoteAwardToAccomplishment(TeamAward award) async {
    final displayOrderController = TextEditingController(text: '0');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Team Accomplishment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Promote "${award.title}" to a team-wide accomplishment?'),
            const SizedBox(height: 16),
            const Text(
              'This will create a new accomplishment on the team home page.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: displayOrderController,
              decoration: const InputDecoration(
                labelText: 'Display Order',
                hintText: '0 = show first',
                helperText: 'Lower numbers appear first',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final displayOrder = int.tryParse(displayOrderController.text) ?? 0;
        await award.promoteToAccomplishment(displayOrder: displayOrder);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Promoted to team accomplishment!'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to team home page
                  final databaseId = DatabaseService.instance.publicShareId;
                  if (databaseId != null) {
                    NavigationHelper.navigateTo(
                      context,
                      '/team/$databaseId',
                    );
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error promoting award: ${e.toString()}'),
            ),
          );
        }
      }
    }

    displayOrderController.dispose();
  }

  Future<void> _deleteTeamAward(TeamAward award) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team Award'),
        content: Text('Delete "${award.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await award.delete();

        if (mounted) {
          setState(() {
            // Clear cache to force reload of awards
            _awardsFutureCache.remove(award.seasonId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team award deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error deleting team award: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showTeamAwardDetailsDialog(TeamAward award) {
    AwardDetailDialog.show(
      context,
      title: award.title,
      description: award.description,
      imageUrl: award.imageUrl,
      url: award.url,
      headerIcon: Icons.emoji_events,
      headerIconColor: Colors.amber,
      heroTagPrefix: 'team_award_${award.id}',
    );
  }

  void _showPlayerAwardDetailsDialog(PlayerAward award, Player player) {
    // Use profileImage if available, otherwise fall back to actionPhoto
    final awardImageUrl = (award.imageUrl != null && award.imageUrl!.isNotEmpty)
        ? award.imageUrl
        : (player.profileImage != null && player.profileImage!.isNotEmpty)
            ? player.profileImage
            : player.actionPhoto;

    AwardDetailDialog.show(
      context,
      title: award.title,
      description: award.description,
      imageUrl: awardImageUrl,
      url: award.url,
      headerIcon: Icons.emoji_events,
      headerIconColor: Colors.amber,
      heroTagPrefix: 'player_award_${award.id}_${player.id}',
      additionalContent: [
        // Player profile link
        InkWell(
          onTap: () {
            Navigator.pop(context);
            final databaseId = DatabaseService.instance.publicShareId;
            if (databaseId != null) {
              NavigationHelper.navigateTo(
                context,
                '/team/$databaseId/season/${award.seasonId}/players/${player.id}',
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.displayName,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'View Profile',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward,
                    color: Colors.blue.shade700, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddPlayerAwardDialog(Season season) {
    // Only supported on mobile
    if (kIsWeb) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Player? selectedPlayer =
        season.players.isNotEmpty ? season.players.first : null;
    String? imageUrl;
    File? imageFile;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Player Award'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (season.players.isEmpty) ...[
                  const Text(
                      'No players found for this season. Add players first.'),
                ] else ...[
                  DropdownButtonFormField<Player>(
                    initialValue: selectedPlayer,
                    decoration: const InputDecoration(
                      labelText: 'Player',
                    ),
                    items: season.players.map((p) {
                      return DropdownMenuItem(
                          value: p, child: Text(p.displayName));
                    }).toList(),
                    onChanged: (p) => setState(() => selectedPlayer = p),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: 'Award Title *'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // Image picker button
                  if (imageUrl != null)
                    Stack(
                      children: [
                        TappableImage.network(
                          imageUrl: imageUrl!,
                          height: 150,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(8),
                          heroTag: 'game_photo_preview',
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                imageUrl = null;
                                imageFile = null;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: isUploadingImage
                          ? null
                          : () async {
                              setState(() {
                                isUploadingImage = true;
                              });
                              try {
                                final pickedFile = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  setState(() {
                                    imageFile = File(pickedFile.path);
                                    isUploadingImage = false;
                                  });
                                } else {
                                  setState(() {
                                    isUploadingImage = false;
                                  });
                                }
                              } catch (e) {
                                setState(() {
                                  isUploadingImage = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error picking image: ${e.toString()}'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image),
                      label:
                          Text(isUploadingImage ? 'Loading...' : 'Pick Image'),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: season.players.isEmpty || selectedPlayer == null
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty || selectedPlayer == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Title and player are required')));
                        return;
                      }

                      try {
                        String? finalImageUrl = imageUrl;
                        if (imageFile != null) {
                          final path =
                              'player_awards/${selectedPlayer!.id}_${DateTime.now().millisecondsSinceEpoch}';
                          final storageRef =
                              FirebaseStorage.instance.ref().child(path);
                          await storageRef.putFile(imageFile!);
                          finalImageUrl = await storageRef.getDownloadURL();
                        }

                        final a = PlayerAward(
                          id: DateTime.now().millisecondsSinceEpoch,
                          playerId: selectedPlayer!.id,
                          seasonId: season.id,
                          title: title,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          imageUrl: finalImageUrl,
                        );

                        await a.save();

                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {
                            // Clear cache to force reload of awards
                            _awardsFutureCache.remove(season.id);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Player award saved')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('Error saving award: ${e.toString()}')));
                        }
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
