import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WebViewerPage extends StatelessWidget {
  final String databaseId;

  const WebViewerPage({super.key, required this.databaseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeamSync Database Viewer'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('shared_databases')
            .doc(databaseId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Database not found.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading database.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final tables = data.keys.toList();

          return ListView.builder(
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final tableName = tables[index];
              final tableData = data[tableName] as List<dynamic>;

              if (tableData.isEmpty) {
                return ExpansionTile(
                  title: Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: const [ListTile(title: Text('No data'))],
                );
              }

              final columns = (tableData.first as Map<String, dynamic>).keys.toList();

              return ExpansionTile(
                title: Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: columns.map((col) => DataColumn(label: Text(col))).toList(),
                      rows: tableData.map((row) {
                        final rowData = row as Map<String, dynamic>;
                        return DataRow(
                          cells: columns.map((col) {
                            return DataCell(Text(rowData[col]?.toString() ?? ''));
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
