import 'dart:async';

import 'package:flutter/foundation.dart';
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
  DateTime? _lastSync;
  DateTime? _lastUpdated;
  late final Stream<bool> _connStream;
  late final Stream<int> _pendingStream;
  late final Stream<DateTime?> _lastSyncStream;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<DateTime?>? _lastSyncSub;
  StreamSubscription<DateTime?>? _updateSub;

  @override
  void initState() {
    super.initState();
    _connStream = DatabaseService.instance.connectionState;
    _pendingStream = DatabaseService.instance.pendingWrites;
    _lastSyncStream = DatabaseService.instance.lastSync;

    // Prime with default values by listening and keeping subscriptions so we can cancel later
    _connSub = _connStream.listen((v) {
      if (mounted) setState(() => _connected = v);
    });
    _pendingSub = _pendingStream.listen((c) {
      if (mounted) setState(() => _pending = c);
    });
    _lastSyncSub = _lastSyncStream.listen((t) {
      if (mounted) setState(() => _lastSync = t);
    });

    // On web, show 'last updated' (database observed update times) instead of last sync.
    if (kIsWeb) {
      _updateSub = DatabaseService.instance.databaseUpdates.listen((t) {
        if (mounted) setState(() => _lastUpdated = t);
      });
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _pendingSub?.cancel();
    _lastSyncSub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }

  String _compactLastSync() {
    final dt = (kIsWeb ? _lastUpdated : _lastSync);
    if (dt == null) return 'never';
    final ldt = dt.toLocal();
    // Keep it compact: YYYY-MM-DD HH:MM
    final y = ldt.year.toString().padLeft(4, '0');
    final m = ldt.month.toString().padLeft(2, '0');
    final d = ldt.day.toString().padLeft(2, '0');
    final hh = ldt.hour.toString().padLeft(2, '0');
    final mm = ldt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final color = _connected ? Colors.greenAccent : Colors.grey[400];
    final icon = _connected ? Icons.cloud_done : Icons.cloud_off;

    final label = kIsWeb
        ? 'Last updated: ${_compactLastSync()}'
        : 'Last sync: ${_compactLastSync()}';
    final tooltip = _connected ? 'Connected\n$label' : 'Offline\n$label';

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
          Text(
            _compactLastSync(),
            style: TextStyle(
                fontSize: 12,
                color: Color.fromARGB((0.9 * 255).toInt(), 255, 255, 255)),
          ),
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
