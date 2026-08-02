import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/features/social_media/services/twitter_credentials_service.dart';
import 'package:team_sync/core/widgets/standard_appbar.dart';

class TwitterSettingsPage extends StatefulWidget {
  final Team? team;

  const TwitterSettingsPage({required this.team, super.key});

  @override
  State<TwitterSettingsPage> createState() => _TwitterSettingsPageState();
}

class _TwitterSettingsPageState extends State<TwitterSettingsPage> {
  // A GlobalKey to uniquely identify the Form widget and allow validation.
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage the text being entered into each field.
  late final TextEditingController _consumerKeyController;
  late final TextEditingController _consumerSecretController;
  late final TextEditingController _accessTokenController;
  late final TextEditingController _accessTokenSecretController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAdmin = false;
  bool _hasExistingCredentials = false;

  @override
  void initState() {
    super.initState();
    _consumerKeyController = TextEditingController();
    _consumerSecretController = TextEditingController();
    _accessTokenController = TextEditingController();
    _accessTokenSecretController = TextEditingController();

    _checkAdminAndLoadCredentials();
  }

  /// Check if current user is a team admin and load credentials
  Future<void> _checkAdminAndLoadCredentials() async {
    if (widget.team == null) {
      setState(() {
        _isLoading = false;
        _isAdmin = false;
      });
      return;
    }

    // Check if user is admin (includes both team creators and admins)
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = widget.team!.isTeamAdmin(currentUser?.uid);

    setState(() {
      _isAdmin = isAdmin;
    });

    if (!isAdmin) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Load credentials from Firebase
    await _loadSavedCredentials();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    // to free up resources.
    _consumerKeyController.dispose();
    _consumerSecretController.dispose();
    _accessTokenController.dispose();
    _accessTokenSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    if (widget.team == null) return;

    try {
      final credentials =
          await TwitterCredentialsService.loadCredentials(widget.team!.id);

      if (credentials != null) {
        // Set flag if any credential field has content
        final hasCredentials = !credentials.isEmpty;

        setState(() {
          _hasExistingCredentials = hasCredentials;
          // Populate form fields with actual values
          _consumerKeyController.text = credentials.consumerKey;
          _consumerSecretController.text = credentials.consumerSecret;
          _accessTokenController.text = credentials.accessToken;
          _accessTokenSecretController.text = credentials.accessTokenSecret;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading credentials: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Validates and saves the form data.
  Future<void> _saveSettings() async {
    final loc = AppLocalizations.of(context)!;
    // Validate returns true if the form is valid, or false otherwise.
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseCorrectFormErrors),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noTeamSelected),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save encrypted credentials to Firebase
      await TwitterCredentialsService.saveCredentials(
        teamId: widget.team!.id,
        consumerKey: _consumerKeyController.text.trim(),
        consumerSecret: _consumerSecretController.text.trim(),
        accessToken: _accessTokenController.text.trim(),
        accessTokenSecret: _accessTokenSecretController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.twitterSettingsSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: widget.team,
        title: const Text('Twitter API Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isAdmin
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Only team creators and admins can manage Twitter API settings.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                _buildInfoCard(),
                                const SizedBox(height: 16),
                                if (_hasExistingCredentials)
                                  _buildStoredCredentialsCard(),
                                const SizedBox(height: 24),
                                _buildTextFormField(
                                  controller: _consumerKeyController,
                                  labelText: 'Consumer Key',
                                  hintText: 'Enter your API consumer key',
                                ),
                                const SizedBox(height: 16),
                                _buildTextFormField(
                                  controller: _consumerSecretController,
                                  labelText: 'Consumer Secret',
                                  hintText: 'Enter your API consumer secret',
                                  isSecret: true,
                                ),
                                const SizedBox(height: 16),
                                _buildTextFormField(
                                  controller: _accessTokenController,
                                  labelText: 'Access Token',
                                  hintText: 'Enter your access token',
                                ),
                                const SizedBox(height: 16),
                                _buildTextFormField(
                                  controller: _accessTokenSecretController,
                                  labelText: 'Access Token Secret',
                                  hintText: 'Enter your access token secret',
                                  isSecret: true,
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _saveSettings,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Save Settings',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Helper method to create a styled TextFormField.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isSecret = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isSecret,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }

  /// Helper method to create the info card at the top.
  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Enter your credentials from the Twitter Developer Portal. These values will be encrypted and stored securely in your team database, accessible to all team creators and admins.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to show status when credentials are already stored
  Widget _buildStoredCredentialsCard() {
    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Twitter credentials are currently stored for this team. Update the fields below to change them.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
