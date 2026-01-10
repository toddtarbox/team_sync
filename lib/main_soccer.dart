import 'package:team_sync/main_common.dart';
import 'package:team_sync/services/soccer_strategy.dart';

import 'package:team_sync/firebase_options.dart';

void main() async {
  await mainCommon(SoccerStrategy(), () => DefaultFirebaseOptions.soccer);
}
