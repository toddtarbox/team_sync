import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:team_sync/main.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/auth_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/twitter_settings_page.dart';

import 'markdown_viewer.dart';

class SettingsPage extends StatefulWidget {
  final Team? team;
  final Club? club;

  const SettingsPage({required this.team, this.club, super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Get the name of the authentication provider (Google or Apple)
  String _getAuthProviderName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Unknown';

    // Check provider data to determine which provider was used
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return 'Google';
      } else if (provider.providerId == 'apple.com') {
        return 'Apple';
      }
    }

    // Fallback - check email domain
    if (user.email?.contains('@privaterelay.appleid.com') == true) {
      return 'Apple';
    }

    return 'Unknown';
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out? You will need to sign in again to access cloud databases.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Close any open database
        await DatabaseService.instance.close();

        // Clear last used database from secure storage
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'last_db_used');

        // Sign out from Firebase
        await AuthService.instance.signOut();

        if (mounted) {
          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home to trigger fresh state
          // Using go instead of pop to ensure TeamHomePage rebuilds with clean state
          context.go('/');
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = _getAuthProviderName();

    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: widget.team,
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return ListView(
            children: [
              if (widget.team != null) ...[
                CommonPageHeader(team: widget.team!),
                Breadcrumbs(
                  items: widget.club != null
                      ? buildClubBreadcrumbs(
                          clubName: widget.club!.name,
                          clubId: widget.club!.id.toString(),
                          additionalLabel: 'Settings',
                        )
                      : buildTeamBreadcrumbs(
                          databaseId:
                              DatabaseService.instance.publicShareId ?? '',
                          teamName: widget.team!.fullName,
                          additionalLabel: 'Settings',
                        ),
                ),
              ],
              // Account Section
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (user != null) ...[
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(user.email ?? 'No email'),
                  subtitle: Row(
                    children: [
                      Icon(
                        authProvider == 'Google'
                            ? Icons.g_mobiledata
                            : Icons.apple,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('Signed in with $authProvider'),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _handleLogout,
                ),
              ] else ...[
                const ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Not signed in'),
                  subtitle: Text('Sign in to access cloud databases'),
                ),
              ],
              const Divider(),
              // Appearance Section
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('Automatic Theme'),
                subtitle: const Text(
                    'Automatically switch theme based on the time of day'),
                value: themeNotifier.isAutoMode,
                onChanged: (bool value) {
                  themeNotifier.setAutoMode(value);
                },
              ),
              const Divider(),
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                value: ThemeMode.light,
                groupValue: themeNotifier.themeMode,
                onChanged: themeNotifier.isAutoMode
                    ? null
                    : (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: themeNotifier.themeMode,
                onChanged: themeNotifier.isAutoMode
                    ? null
                    : (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: themeNotifier.themeMode,
                onChanged: themeNotifier.isAutoMode
                    ? null
                    : (ThemeMode? value) {
                        if (value != null) {
                          themeNotifier.setThemeMode(value);
                        }
                      },
              ),
              const Divider(),
              // Other Settings Section
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  'Other',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Visibility(
                visible: !kIsWeb,
                child: ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Twitter Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            TwitterSettingsPage(team: widget.team),
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MarkdownViewer(
                        file: 'PRIVACY_POLICY.md',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Use'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MarkdownViewer(
                        file: 'TERMS_OF_USE.md',
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
