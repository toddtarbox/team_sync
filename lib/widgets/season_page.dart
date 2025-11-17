import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/game_result.dart';
import 'package:team_sync/widgets/scoreboard.dart';
import 'package:team_sync/widgets/scoring_summary.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/season_with_logo.dart';
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

  // Helper to get path segments that works with hash-based routing used by go_router on web.
  List<String> _getPathSegments() {
    final uri = Uri.base;
    if (uri.fragment.isNotEmpty) {
      // Fragment may contain a path like '/team/123/season/45'
      try {
        final fragUri = Uri.parse(uri.fragment);
        if (fragUri.pathSegments.isNotEmpty) {
          debugPrint('Using fragment pathSegments: ${fragUri.pathSegments}');
          return fragUri.pathSegments;
        }
      } catch (e) {
        // ignore and fall back to pathSegments
        debugPrint('Failed to parse fragment as URI: $e');
      }
    }
    debugPrint('Using base pathSegments: ${uri.pathSegments}');
    return uri.pathSegments;
  }

  @override
  void initState() {
    super.initState();
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
              appBar: CustomAppBar(
                team: season.team,
                title: Text(season.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(180),
                    child: SeasonWithLogo(season: season)),
              ),
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
              body: Center(
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
                            AppLocalizations.of(context)!.createNewGameToStart,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.blue))),
                  ])),
            );
          }

          return Scaffold(
              appBar: CustomAppBar(
                team: season.team,
                title: Text(season.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(180),
                    child: SeasonWithLogo(season: season)),
              ),
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          season.team.color1,
                          season.team.color2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
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
                      ),
                    ),
                  ),
                ],
              ));
        } else if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          debugPrintStack(stackTrace: snapshot.stackTrace);
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
      debugPrint('SeasonPage: starting _loadSeason');
      // Determine path segments early for logging
      final initialSegments = _getPathSegments();
      debugPrint('SeasonPage: pathSegments -> $initialSegments');
      // Ensure the database is opened for the shared database id in the URL
      try {
        final segmentsForDb = _getPathSegments();
        debugPrint('SeasonPage: segmentsForDb -> $segmentsForDb');
        final teamIndex = segmentsForDb.indexOf('team');
        if (teamIndex != -1 && teamIndex + 1 < segmentsForDb.length) {
          final dbId = segmentsForDb[teamIndex + 1];
          debugPrint('SeasonPage: found dbId in URL -> $dbId');
          if (DatabaseService.instance.publicShareId == null ||
              DatabaseService.instance.publicShareId != dbId) {
            // try opening the shared DB but don't block forever
            try {
              final opened = await DatabaseService.instance
                  .openFromId(dbId)
                  .timeout(const Duration(seconds: 10));
              debugPrint('SeasonPage: openFromId($dbId) returned $opened');
              if (!opened) {
                throw Exception('Failed to open shared database: $dbId');
              }
            } catch (te) {
              if (te is TimeoutException) {
                debugPrint('SeasonPage: openFromId($dbId) timed out: $te');
              } else {
                debugPrint('SeasonPage: openFromId($dbId) failed: $te');
              }
              rethrow;
            }
          }
        }
      } catch (e) {
        debugPrint('Error opening DB from URL in SeasonPage: $e');
        rethrow;
      }
      final segments = _getPathSegments();
      debugPrint('SeasonPage: resolving season from segments -> $segments');
      final seasonIndex = segments.indexOf('season');
      if (seasonIndex == -1 || seasonIndex + 1 >= segments.length) {
        throw Exception('Season id not found in URL');
      }

      final seasonIdString = segments[seasonIndex + 1];
      final seasonId = int.parse(seasonIdString);

      debugPrint('SeasonPage: querying Seasons for id $seasonId');
      List<Map<String, dynamic>> results;
      try {
        results = await DatabaseService.instance
            .query('Seasons', orderByChild: 'id', equalTo: seasonId)
            .timeout(const Duration(seconds: 10));
      } catch (te) {
        if (te is TimeoutException) {
          debugPrint('SeasonPage: query timed out for season $seasonId: $te');
        } else {
          debugPrint('SeasonPage: query failed for season $seasonId: $te');
        }
        rethrow;
      }

      debugPrint('SeasonPage: query returned ${results.length} rows');
      if (results.isEmpty) {
        throw Exception('Season not found: $seasonId');
      }

      final season = Season.fromMap(results.first);
      await season.load();
      debugPrint(
          'SeasonPage: season loaded id=${season.id} name=${season.name}');
      return season;
    } catch (e) {
      debugPrint('Error loading season in SeasonPage: $e');
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
                      Scoreboard(game, s, color: Colors.black, shortName: true),
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
}
