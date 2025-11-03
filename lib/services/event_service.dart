import 'package:eventify/eventify.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  final EventEmitter eventEmitter = EventEmitter();

  factory EventService() {
    return _instance;
  }

  EventService._internal();
}
