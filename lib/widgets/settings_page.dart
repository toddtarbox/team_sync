import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/main.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/auth_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/locale_notifier.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
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

  /// Get the display name for a locale code
  String _getLocaleName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      default:
        return languageCode.toUpperCase();
    }
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.logOut),
          content: Text(loc.logOutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(loc.logOut),
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
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.loggedOutSuccessfully),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home to trigger fresh state
          // Using replaceRoute to ensure TeamHomePage rebuilds with clean state
          NavigationHelper.replaceRoute(context, '/');
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
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final authProvider = _getAuthProviderName();

    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: widget.team,
        title: Text(loc.settings),
      ),
      body: Consumer2<ThemeNotifier, LocaleNotifier>(
        builder: (context, themeNotifier, localeNotifier, child) {
          return ListView(
            children: [
              if (widget.team != null) ...[
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
              // Account Section (hidden on web)
              Visibility(
                visible: !kIsWeb,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Text(
                        loc.account,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (user != null) ...[
                      ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: Text(user.email ?? loc.noEmail),
                        subtitle: Row(
                          children: [
                            Icon(
                              authProvider == 'Google'
                                  ? Icons.g_mobiledata
                                  : Icons.apple,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(loc.signedInWith(authProvider)),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text(
                          loc.logOut,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: _handleLogout,
                      ),
                    ] else ...[
                      ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: Text(loc.notSignedIn),
                        subtitle: Text(loc.signInToAccessCloudDatabases),
                      ),
                    ],
                    const Divider(),
                  ],
                ),
              ),
              // Appearance Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  loc.appearance,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SwitchListTile(
                title: Text(loc.automaticTheme),
                subtitle: Text(loc.automaticThemeSwitchDescription),
                value: themeNotifier.isAutoMode,
                onChanged: (bool value) {
                  themeNotifier.setAutoMode(value);
                },
              ),
              const Divider(),
              RadioListTile<ThemeMode>(
                title: Text(loc.lightMode),
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
                title: Text(loc.themeDarkMode),
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
                title: Text(loc.systemDefaultTheme),
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
              // Language Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  loc.language,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              RadioListTile<String?>(
                title: Text(loc.systemDefaultLanguage),
                subtitle: Text(
                  localeNotifier.locale == null
                      ? '${loc.currently}: ${_getLocaleName(Localizations.localeOf(context).languageCode)}'
                      : loc.useDeviceLanguage,
                  style: const TextStyle(fontSize: 12),
                ),
                value: null,
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  localeNotifier.resetToSystemDefault();
                },
              ),
              RadioListTile<String>(
                title: const Text('🇺🇸 English'),
                value: 'en',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('🇪🇸 Español'),
                value: 'es',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('🇫🇷 Français'),
                value: 'fr',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('🇩🇪 Deutsch'),
                value: 'de',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('🇮🇹 Italiano'),
                value: 'it',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('🇧🇷 Português'),
                value: 'pt',
                groupValue: localeNotifier.locale?.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    localeNotifier.setLocale(Locale(value));
                  }
                },
              ),
              const Divider(),
              // Other Settings Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Text(
                  loc.other,
                  style: const TextStyle(
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
                  title: Text(loc.twitterSettings),
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
                title: Text(loc.privacyPolicy),
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
                title: Text(loc.termsOfUse),
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
