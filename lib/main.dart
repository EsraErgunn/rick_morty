import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/start_route.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // START_ROUTE is a debug/profile helper for perf runs; release ignores it.
  await configureDependencies(
    initialLocation: resolveStartRoute(isRelease: kReleaseMode),
  );
  runApp(PortalCardsApp(router: getIt<GoRouter>()));
}
