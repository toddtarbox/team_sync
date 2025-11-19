import 'package:flutter/material.dart';
import 'package:team_sync/services/database_service.dart';

/// Widget to display and open databases shared by other users.
class SharedDatabasesWidget extends StatefulWidget {
  final Function(String ownerId, String databaseName)? onDatabaseSelected;

  const SharedDatabasesWidget({
    super.key,
    this.onDatabaseSelected,
  });

  @override
  State<SharedDatabasesWidget> createState() => _SharedDatabasesWidgetState();
}

class _SharedDatabasesWidgetState extends State<SharedDatabasesWidget> {
  List<Map<String, dynamic>> _sharedDatabases = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSharedDatabases();
  }

  Future<void> _loadSharedDatabases() async {
    setState(() => _isLoading = true);
    try {
      final databases = await DatabaseService.instance.getSharedDatabasesInfo();
      setState(() {
        _sharedDatabases = databases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shared databases: $e')),
        );
      }
    }
  }

  Future<void> _openSharedDatabase(String ownerId, String databaseName) async {
    setState(() => _isLoading = true);
    try {
      final success = await DatabaseService.instance
          .openSharedDatabase(ownerId, databaseName);

      if (success) {
        if (widget.onDatabaseSelected != null) {
          widget.onDatabaseSelected!(ownerId, databaseName);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened database: $databaseName')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open database')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shared with Me',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadSharedDatabases,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_sharedDatabases.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No shared databases',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Databases shared with you will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sharedDatabases.length,
            itemBuilder: (context, index) {
              final db = _sharedDatabases[index];
              final ownerEmail = db['ownerEmail']?.toString() ?? 'Unknown';
              final databaseName = db['databaseName']?.toString() ?? 'Unnamed';
              final accessLevel = db['accessLevel']?.toString() ?? 'read';
              final ownerId = db['ownerId']?.toString() ?? '';
              final grantedAt = db['grantedAt'];

              String timeAgo = '';
              if (grantedAt != null) {
                try {
                  final timestamp = grantedAt is int
                      ? grantedAt
                      : int.tryParse(grantedAt.toString());
                  if (timestamp != null) {
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final diff = DateTime.now().difference(date);
                    if (diff.inDays > 0) {
                      timeAgo = '${diff.inDays}d ago';
                    } else if (diff.inHours > 0) {
                      timeAgo = '${diff.inHours}h ago';
                    } else {
                      timeAgo = '${diff.inMinutes}m ago';
                    }
                  }
                } catch (e) {
                  // Silently ignore parsing errors
                }
              }

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      accessLevel == 'write' ? Icons.edit : Icons.visibility,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(databaseName),
                  subtitle: Text(
                    'Shared by $ownerEmail\n${accessLevel == 'read' ? 'Read Only' : 'Read & Write'}${timeAgo.isNotEmpty ? ' • $timeAgo' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => _openSharedDatabase(ownerId, databaseName),
                ),
              );
            },
          ),
      ],
    );
  }
}
