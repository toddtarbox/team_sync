import 'package:team_sync/main_common.dart';
import 'package:team_sync/services/basketball_strategy.dart';

import 'package:team_sync/firebase_options.dart';

void main() async {
  await mainCommon(
      BasketballStrategy(), () => DefaultFirebaseOptions.basketball);
}
