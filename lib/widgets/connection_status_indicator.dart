import 'dart:async';

import 'package:flutter/material.dart';
import 'package:team_sync/services/database_service.dart';

/// Shows current RTDB connection state and pending write count.
class ConnectionStatusIndicator extends StatefulWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator> {
  bool _connected = true;
  int _pending = 0;
  late final Stream<bool> _connStream;
  late final Stream<int> _pendingStream;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _connStream = DatabaseService.instance.connectionState;
    _pendingStream = DatabaseService.instance.pendingWrites;

    // Prime with default values by listening and keeping subscriptions so we can cancel later
    _connSub = _connStream.listen((v) {
      if (mounted) setState(() => _connected = v);
    });
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
    final color = _connected ? Colors.greenAccent : Colors.grey[400];
    final icon = _connected ? Icons.cloud_done : Icons.cloud_off;
    final tooltip = _connected ? 'Connected' : 'Offline';

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: tooltip,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 6),
          if (_pending > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$_pending',
                  style: const TextStyle(fontSize: 12, color: Colors.black)),
            ),
          ]
        ],
      ),
    );
  }
}
