import 'package:flutter/material.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/admin_management_service.dart';

/// Dialog for managing club or team admins
class AdminManagementDialog extends StatefulWidget {
  final Club? club;
  final Team? team;

  const AdminManagementDialog({
    super.key,
    this.club,
    this.team,
  }) : assert(club != null || team != null,
            'Either club or team must be provided');

  @override
  State<AdminManagementDialog> createState() => _AdminManagementDialogState();
}

class _AdminManagementDialogState extends State<AdminManagementDialog> {
  final _service = AdminManagementService.instance;
  final _emailController = TextEditingController();
  List<Map<String, String>> _admins = [];
  bool _loading = true;
  String? _error;
  bool _isClubManagement = false;

  @override
  void initState() {
    super.initState();
    _isClubManagement = widget.club != null;
    _loadAdmins();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final admins = _isClubManagement
          ? await _service.getClubAdmins(widget.club!)
          : await _service.getTeamAdmins(widget.team!);

      setState(() {
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = _isClubManagement
          ? await _service.addClubAdmin(widget.club!, email)
          : await _service.addTeamAdmin(widget.team!, email, club: widget.club);

      if (success) {
        _emailController.clear();
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin added successfully')),
          );
        }
      } else {
        setState(() {
          _error = 'User is already an admin';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeAdmin(String adminId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = _isClubManagement
          ? await _service.removeClubAdmin(widget.club!, adminId)
          : await _service.removeTeamAdmin(widget.team!, adminId,
              club: widget.club);

      if (success) {
        await _loadAdmins();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin removed successfully')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isClubManagement ? 'Manage Club Admins' : 'Manage Team Admins';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add admin section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'User Email',
                      hintText: 'Enter email to add as admin',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addAdmin(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _addAdmin,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Current admins list
            if (_loading && _admins.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else if (_admins.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No admins yet'),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _admins.length,
                  itemBuilder: (context, index) {
                    final admin = _admins[index];
                    final isCreator = admin['role'] == 'Creator';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          admin['email']![0].toUpperCase(),
                        ),
                      ),
                      title: Text(admin['email']!),
                      subtitle: Text(admin['role']!),
                      trailing: isCreator
                          ? const Chip(
                              label: Text('Creator'),
                              backgroundColor: Colors.blue,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed: _loading
                                  ? null
                                  : () => _confirmRemoveAdmin(admin['id']!),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _confirmRemoveAdmin(String adminId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text(
          'Are you sure you want to remove this admin? '
          'They will lose access to manage this ${_isClubManagement ? 'club' : 'team'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeAdmin(adminId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
