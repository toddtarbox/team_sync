import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team_sync/main.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/twitter_settings_page.dart';

class SettingsPage extends StatelessWidget {
  final Team? team;

  const SettingsPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        team: team,
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return ListView(
            children: [
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
              ListTile(
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
            ],
          );
        },
      ),
    );
  }
}
