import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(PortalCardsApp(router: getIt<GoRouter>()));
}
