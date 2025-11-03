import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_record.dart';

class SeasonsListView extends StatefulWidget {
  const SeasonsListView({
    super.key,
    required this.seasons,
  });

  final List<Season> seasons;

  @override
  State<SeasonsListView> createState() => _SeasonsListViewState();
}

class _SeasonsListViewState extends State<SeasonsListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.seasons.length,
        itemBuilder: (context, index) {
          final season = widget.seasons[index];
          final seasonCard = GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeasonPage(season: season),
                  ),
                );
              },
              child: Card(
                  child: Column(children: [
                Text(season.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(5),
                    margin: const EdgeInsets.all(10),
                    child: Center(child: SeasonRecord([season]))),
              ])));
          return Dismissible(
              key: Key(season.id.toString()),
              background: Container(color: Theme.of(context).colorScheme.error),
              behavior: HitTestBehavior.translucent,
              confirmDismiss: (_) {
                return showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.confirmDelete),
                      content: Text(AppLocalizations.of(context)!
                          .areYouSureYouWantToDeleteThisSeason),
                      actions: [
                        TextButton(
                          child: Text(
                              AppLocalizations.of(context)!.continueButton),
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                        ),
                        TextButton(
                          child:
                              Text(AppLocalizations.of(context)!.cancelButton),
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
                await DatabaseService.instance
                    .delete('Seasons', where: 'id=?', whereArgs: [season.id]);
                setState(() {});
              },
              child: seasonCard);
        });
  }
}
