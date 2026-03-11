import 'package:flutter/material.dart';

import 'core/core.dart';
import 'core/services/coin_service.dart';
import 'inject/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initInjection();
  await CoinService.instance.init();
  runApp(const WormJourneyApp());
}
