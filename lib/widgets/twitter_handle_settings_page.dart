import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TwitterHandleSettingsPage extends StatefulWidget {
  final Team? team;
  const TwitterHandleSettingsPage({required this.team, super.key});

  @override
  State<TwitterHandleSettingsPage> createState() =>
      _TwitterHandleSettingsPageState();
}

class _TwitterHandleSettingsPageState extends State<TwitterHandleSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _handleController;
  bool _showPreview = false;
  WebViewController? _webViewController;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController();
    _loadHandle();
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _loadHandle() async {
    if (widget.team != null) {
      final handle = widget.team!.twitterHandle ?? '';
      _handleController.text = handle;
      setState(() {});
    }
  }

  Future<void> _saveHandle() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No team selected')),
      );
      return;
    }

    var handle = _handleController.text.trim();
    if (handle.startsWith('@')) handle = handle.substring(1);

    try {
      await DatabaseService.instance.update(
        'Teams',
        {'twitterHandle': handle.isEmpty ? null : handle},
        key: widget.team!.id.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Twitter handle saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(team: widget.team, title: const Text('Twitter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Twitter feed handle (without @)',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. TeamSyncApp',
                ),
                // allow blank, so user can clear to use the default account
                validator: (v) {
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveHandle,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final handle = _handleController.text.trim();
                      if (handle.isEmpty) return;
                      final h =
                          handle.startsWith('@') ? handle.substring(1) : handle;
                      final url = Uri.https('twitter.com', '/$h');
                      // Show inline WebView on non-web platforms
                      if (!kIsWeb) {
                        setState(() {
                          _previewUrl = url.toString();
                          _showPreview = true;
                          _webViewController = WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..loadRequest(Uri.parse(_previewUrl!));
                        });
                      } else {
                        // Fallback to opening browser on web
                        if (!await launchUrl(url)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Could not open Twitter')),
                          );
                        }
                      }
                    },
                    child: const Text('Preview'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showPreview && _previewUrl != null && !kIsWeb)
                SizedBox(
                  height: 360,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: WebViewWidget(controller: _webViewController!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
