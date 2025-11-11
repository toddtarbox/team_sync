import 'dart:async';

import 'package:flutter/material.dart';
import 'package:team_sync/services/database_service.dart';

class DebugMigrationPage extends StatefulWidget {
  const DebugMigrationPage({super.key});

  @override
  State<DebugMigrationPage> createState() => _DebugMigrationPageState();
}

class _DebugMigrationPageState extends State<DebugMigrationPage> {
  final TextEditingController _pathController = TextEditingController(
      text:
          'subscriptionIds/QIDgbt5JbsTVR5goGtfRtjubXUO2/databases/SaintAlbert.db');
  bool _running = false;
  final List<String> _logs = [];
  StreamSubscription<ImportProgress>? _progressSub;
  final Map<String, ImportProgress> _tableProgress = {};

  void _appendLog(String msg) {
    setState(
        () => _logs.insert(0, '${DateTime.now().toIso8601String()} - $msg'));
  }

  Future<void> _runMigration() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      _appendLog('Please enter a Firestore document path.');
      return;
    }

    setState(() {
      _running = true;
      _logs.clear();
      _tableProgress.clear();
    });

    startImport();

    _progressSub = importProgressStream.listen((p) {
      setState(() {
        _tableProgress[p.table] = p;
      });
      _appendLog(
          'Progress ${p.stage} ${p.table}: ${p.processed}/${p.total}${p.message != null ? ' - ${p.message}' : ''}');
    });

    _appendLog('Starting migration for "$path"');

    try {
      await DatabaseService.instance.importFromFirestore(path);
      _appendLog('Migration completed successfully.');
    } catch (e, st) {
      _appendLog('Migration failed: $e');
      _appendLog(st.toString());
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
      setState(() {
        _running = false;
      });
    }
  }

  void _cancelMigration() {
    cancelImport();
    _appendLog('Cancellation requested.');
  }

  @override
  void dispose() {
    _pathController.dispose();
    _progressSub?.cancel();
    super.dispose();
  }

  Widget _buildProgressList() {
    if (_tableProgress.isEmpty) return const SizedBox.shrink();
    final rows = _tableProgress.values.toList(growable: false);
    return Column(
      children: rows.map((p) {
        final percent = p.total > 0 ? (p.processed / p.total) : 0.0;
        return ListTile(
          title: Text(p.table),
          subtitle: Text('${p.stage} — ${p.processed}/${p.total}'),
          trailing: SizedBox(
            width: 80,
            child: LinearProgressIndicator(value: percent),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Debug: Firestore → Realtime Migration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firestore document path (the document that contains your collections).',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Firestore document path',
                border: OutlineInputBorder(),
                hintText:
                    "e.g. 'databases/myDb' or 'users/<uid>/databases/myDb'",
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _running ? null : _runMigration,
                  icon: _running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_running ? 'Migrating...' : 'Run Migration'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _running
                      ? null
                      : () {
                          setState(() {
                            _logs.clear();
                            _tableProgress.clear();
                          });
                        },
                  child: const Text('Clear Logs'),
                ),
                const SizedBox(width: 8),
                if (_running)
                  TextButton(
                    onPressed: _cancelMigration,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressList(),
            const SizedBox(height: 16),
            const Text('Logs', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _logs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('No logs yet.'),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 12.0),
                            child: Text(log),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
