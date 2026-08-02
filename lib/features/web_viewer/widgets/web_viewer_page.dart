import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';

/// Shows the contents of a Realtime Database document/tree at [databasePath].
/// Example path: 'subscriptionIds/<uid>/databases/<dbName>'
class WebViewerPage extends StatelessWidget {
  final String databasePath;

  const WebViewerPage({super.key, required this.databasePath});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.teamSyncDatabaseViewer),
      ),
      body: FutureBuilder<DatabaseEvent>(
        future: FirebaseDatabase.instance.ref(databasePath).once(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(loc.errorLoadingDatabase));
          }
          final event = snapshot.data;
          if (event == null || event.snapshot.value == null) {
            return const Center(child: Text('Database not found.'));
          }

          // The shared database mapping may contain nested tables stored as
          // either a List or a Map keyed by id. Normalize each table into a
          // List<Map<String, dynamic>> where each row includes an 'id' field
          // when possible.
          final raw = event.snapshot.value;
          if (raw is! Map) {
            return const Center(child: Text('Unexpected database format.'));
          }

          final data = Map<String, dynamic>.from(raw);
          final tables = data.keys.toList();

          return ListView.builder(
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final tableName = tables[index];
              final tableRaw = data[tableName];

              // Normalize rows
              List<Map<String, dynamic>> rows = [];
              if (tableRaw is List) {
                rows = tableRaw
                    .where((e) => e != null)
                    .map((e) =>
                        e is Map ? Map<String, dynamic>.from(e) : {'value': e})
                    .toList();
              } else if (tableRaw is Map) {
                rows = (tableRaw).entries.map((entry) {
                  final key = entry.key.toString();
                  final val = entry.value;
                  if (val is Map) {
                    final mapVal = Map<String, dynamic>.from(val);
                    mapVal['id'] = key;
                    return mapVal;
                  }
                  return {'id': key, 'value': val};
                }).toList();
              }

              if (rows.isEmpty) {
                return ExpansionTile(
                  title: Text(tableName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [ListTile(title: Text(loc.noData))],
                );
              }

              // Compute union of columns across all rows
              final columnsSet = <String>{};
              for (final r in rows) {
                columnsSet.addAll(r.keys);
              }
              final columns = columnsSet.toList();

              return ExpansionTile(
                title: Text(tableName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: columns
                          .map((col) => DataColumn(label: Text(col)))
                          .toList(),
                      rows: rows.map((row) {
                        return DataRow(
                          cells: columns.map((col) {
                            return DataCell(Text(row[col]?.toString() ?? ''));
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
