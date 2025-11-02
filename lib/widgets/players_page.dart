import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';

class PlayersPage extends StatefulWidget {
  final Season season;
  const PlayersPage({super.key, required this.season});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          team: widget.season.team,
          title: Text(AppLocalizations.of(context)!.players,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        floatingActionButton: kIsWeb
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.season.team.color1,
                      widget.season.team.color2
                    ],
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
                    _createPlayer();
                  },
                )),
        body: FutureBuilder(
          future: DatabaseService.instance.query('Players',
              where: 'seasonId=? AND teamId=?',
              whereArgs: [widget.season.id, widget.season.teamId],
              orderBy: "firstName ASC"),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData) {
              final players = snapshot.data!;
              return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = Player.fromMap(players[index]);
                    return Dismissible(
                        key: Key(player.id.toString()),
                        background: Container(color: Colors.red),
                        confirmDismiss: kIsWeb
                            ? (_) => Future.value(false)
                            : (_) {
                                return showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(AppLocalizations.of(context)!
                                          .confirmDelete),
                                      content: Text(AppLocalizations.of(
                                              context)!
                                          .areYouSureYouWantToDeleteThisPlayer),
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
                          await DatabaseService.instance.delete('Players',
                              where: 'id=? AND seasonId=?',
                              whereArgs: [player.id, widget.season.id]);
                          setState(() {});
                        },
                        child: ListTile(
                          title: Text(player.displayName),
                          subtitle: Text('#${player.number}'),
                        ));
                  });
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }

  void _createPlayer() {
    late String playerName;
    late int playerNumber;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    Text(AppLocalizations.of(context)!.newPlayer),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.playerName),
                        onChanged: (name) => playerName = name),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.playerNumber),
                        onChanged: (number) =>
                            playerNumber = int.parse(number)),
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
                                    if (playerName.isNotEmpty) {
                                      await DatabaseService.instance.insert(
                                          'Players', {
                                        'name': playerName,
                                        'number': playerNumber,
                                        'seasonId': widget.season.id
                                      });

                                      setState(() {});
                                      Navigator.pop(context);
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
}
