import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

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
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.players),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            _createPlayer();
          },
        ),
        body: FutureBuilder(
          future: DatabaseService.instance.query('Players',
              where: 'seasonId=?', whereArgs: [widget.season.id]),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData) {
              final players = snapshot.data!;
              return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = Player.fromMap(players[index]);
                    return ListTile(
                      title: Text(player.displayName),
                      subtitle: Text('#${player.number}'),
                    );
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
