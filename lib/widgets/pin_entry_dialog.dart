import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/services/database_service.dart';

/// Dialog for entering a 4-digit PIN to unlock player profile editing
class PinEntryDialog extends StatefulWidget {
  final Player player;

  const PinEntryDialog({
    super.key,
    required this.player,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() async {
    final pin = _pinController.text.trim();

    // Validate PIN format
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.invalidPin;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Debug logging
    debugPrint('PIN Validation Attempt:');
    debugPrint('  Player ID: ${widget.player.id}');
    debugPrint('  Season ID: ${widget.player.seasonId}');
    debugPrint('  PIN entered: $pin');
    debugPrint('  PIN length: ${pin.length}');
    debugPrint('  Database path: ${DatabaseService.instance.fullDatabasePath}');

    try {
      // Validate PIN via Cloud Function (server-side validation)
      final dbPath = DatabaseService.instance.fullDatabasePath;
      if (dbPath.isEmpty) {
        throw Exception('No database path available');
      }

      final callable =
          FirebaseFunctions.instance.httpsCallable('validatePlayerPin');
      final result = await callable.call<Map<String, dynamic>>({
        'databasePath': dbPath,
        'playerId': widget.player.id,
        'seasonId': widget.player.seasonId,
        'pin': pin,
      });

      debugPrint('PIN validation result: ${result.data}');

      if (result.data['valid'] == true) {
        // PIN is correct - return the PIN value
        debugPrint('PIN validation successful!');
        if (mounted) {
          Navigator.of(context).pop(pin);
        }
      } else {
        // PIN is incorrect
        debugPrint('PIN validation failed: valid = ${result.data['valid']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Incorrect PIN. Please try again.';
            _pinController.clear();
          });
        }
      }
    } catch (e) {
      // Handle errors (invalid PIN, network issues, etc.)
      debugPrint('PIN validation error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e.toString().contains('permission-denied') ||
              e.toString().contains('Invalid PIN')) {
            _errorMessage = 'Incorrect PIN. Please try again.';
          } else if (e.toString().contains('not-found')) {
            _errorMessage = 'No PIN has been set for this player.';
          } else {
            _errorMessage = 'Error validating PIN. Please try again.';
          }
          _pinController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 12),
          Text(loc.enterPinToEdit),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.enterFourDigitPin,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: loc.pinLabel,
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
              counterText: '',
              prefixIcon: const Icon(Icons.pin),
            ),
            onSubmitted: (_) => _verifyPin(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(null),
          child: Text(loc.cancelButton),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _verifyPin,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.unlockButton),
        ),
      ],
    );
  }
}
