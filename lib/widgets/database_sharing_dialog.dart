import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';

/// Dialog for managing database sharing with other users.
class DatabaseSharingDialog extends StatefulWidget {
  const DatabaseSharingDialog({super.key});

  @override
  State<DatabaseSharingDialog> createState() => _DatabaseSharingDialogState();
}

class _DatabaseSharingDialogState extends State<DatabaseSharingDialog> {
  final _emailController = TextEditingController();
  String _accessLevel = 'read';
  bool _isLoading = false;
  List<Map<String, dynamic>> _sharedWith = [];

  @override
  void initState() {
    super.initState();
    _loadAccessList();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessList() async {
    setState(() => _isLoading = true);
    try {
      final accessList = await DatabaseService.instance.getDatabaseAccessList();
      setState(() {
        _sharedWith = accessList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading access list: $e')),
        );
      }
    }
  }

  Future<void> _shareWithUser() async {
    final loc = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseEnterEmailAddress)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await DatabaseService.instance.shareDatabaseWithUser(
        email,
        accessLevel: _accessLevel,
      );

      if (success) {
        _emailController.clear();
        await _loadAccessList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access granted to $email')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToGrantAccess)),
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

  Future<void> _revokeAccess(String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: const Text('Revoke Access'),
          content: Text('Remove access for $email?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Revoke'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success =
          await DatabaseService.instance.unshareDatabaseFromUser(email);

      if (success) {
        await _loadAccessList();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access revoked for $email')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to revoke access')),
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
    final loc = AppLocalizations.of(context)!;
    final isProUser = SubscriptionService.instance.isSubscribed;

    if (!isProUser) {
      return AlertDialog(
        title: const Text('Pro Feature'),
        content: const Text(
          'Database sharing is a Pro feature. Upgrade to TeamSync Pro to share databases with other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SubscriptionService.instance.purchaseSubscription();
            },
            child: Text(loc.upgradeToPro),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Share Database'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grant access to other users by email:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: loc.userEmail,
                hintText: 'user@example.com',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _accessLevel,
              decoration: const InputDecoration(
                labelText: 'Access Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'read', child: Text('Read Only')),
                DropdownMenuItem(value: 'write', child: Text('Read & Write')),
              ],
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _accessLevel = value);
                      }
                    },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _shareWithUser,
                icon: const Icon(Icons.person_add),
                label: const Text('Grant Access'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Users with access:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_sharedWith.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No users have access yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sharedWith.length,
                  itemBuilder: (context, index) {
                    final user = _sharedWith[index];
                    final email = user['email'] as String;
                    final accessLevel = user['accessLevel'] as String;
                    final grantedAt = user['grantedAt'];

                    String timeAgo = '';
                    if (grantedAt is int) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(grantedAt);
                      final diff = DateTime.now().difference(date);
                      if (diff.inDays > 0) {
                        timeAgo = '${diff.inDays}d ago';
                      } else if (diff.inHours > 0) {
                        timeAgo = '${diff.inHours}h ago';
                      } else {
                        timeAgo = '${diff.inMinutes}m ago';
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?'),
                      ),
                      title: Text(email),
                      subtitle: Text(
                        '${accessLevel == 'read' ? 'Read Only' : 'Read & Write'}${timeAgo.isNotEmpty ? ' • $timeAgo' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed:
                            _isLoading ? null : () => _revokeAccess(email),
                        tooltip: 'Revoke access',
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
          onPressed: () => Navigator.pop(context),
          child: Text(loc.close),
        ),
      ],
    );
  }
}
