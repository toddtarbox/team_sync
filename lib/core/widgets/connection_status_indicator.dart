import 'dart:async';

import 'package:flutter/material.dart';
import 'package:team_sync/core/services/database_service.dart';

/// Shows current RTDB connection state and pending write count.
class ConnectionStatusIndicator extends StatefulWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator> {
  int _pending = 0;
  late final Stream<int> _pendingStream;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _pendingStream = DatabaseService.instance.pendingWrites;

    // Prime with default values by listening and keeping subscriptions so we can cancel later
    _pendingSub = _pendingStream.listen((c) {
      if (mounted) setState(() => _pending = c);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pending > 0) ...[
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$_pending',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }
}
