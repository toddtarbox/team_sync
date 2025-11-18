import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team_sync/main.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/debug_migration_page.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/twitter_settings_page.dart';

import 'markdown_viewer.dart';

class SettingsPage extends StatelessWidget {
  final Team? team;
  final Club? club;

  const SettingsPage({required this.team, this.club, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: team,
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return ListView(
            children: [
              if (team != null) CommonPageHeader(team: team!),
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
              Visibility(
                visible: !kIsWeb,
                child: ListTile(
                  title: const Text('Twitter Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TwitterSettingsPage(team: team),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
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
              // Debug-only migration prompt: allows a developer to run
              // Firestore -> Realtime Database import from the app.
              if (kDebugMode) ...[
                const Divider(),
                ListTile(
                  title: const Text('Debug: Import Firestore to RTDB'),
                  leading: const Icon(Icons.cloud_upload),
                  onTap: () {
                    // Navigate to the debug migration page for interactive migration
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const DebugMigrationPage(),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
