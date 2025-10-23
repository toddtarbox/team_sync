import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/custom_appbar.dart';

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

  @override
  void initState() {
    super.initState();
    _consumerKeyController = TextEditingController();
    _consumerSecretController = TextEditingController();
    _accessTokenController = TextEditingController();
    _accessTokenSecretController = TextEditingController();

    _loadSavedCredentials();
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

  void _loadSavedCredentials() async {
    const storage = FlutterSecureStorage();
    _consumerKeyController.text =
        await storage.read(key: 'twitter_consumer_key') ?? '';
    _consumerSecretController.text =
        await storage.read(key: 'twitter_consumer_secret') ?? '';
    _accessTokenController.text =
        await storage.read(key: 'twitter_access_token') ?? '';
    _accessTokenSecretController.text =
        await storage.read(key: 'twitter_access_token_secret') ?? '';
  }

  /// Validates and saves the form data.
  void _saveSettings() {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      // If the form is valid, display a snackbar and proceed.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving Twitter Settings...'),
          backgroundColor: Colors.green,
        ),
      );

      const storage = FlutterSecureStorage();
      storage.write(
          key: 'twitter_consumer_key', value: _consumerKeyController.text);
      storage.write(
          key: 'twitter_consumer_secret',
          value: _consumerSecretController.text);
      storage.write(
          key: 'twitter_access_token', value: _accessTokenController.text);
      storage.write(
          key: 'twitter_access_token_secret',
          value: _accessTokenSecretController.text);

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        team: widget.team,
        title: const Text('Twitter API Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildInfoCard(),
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
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                'Enter your credentials from the Twitter Developer Portal. These values will be stored securely on your device.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
