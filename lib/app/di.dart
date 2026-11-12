import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

/// The app's service locator. Only `main` and composition code read from it;
/// widgets and blocs get their dependencies passed in.
final GetIt getIt = GetIt.instance;

/// Registers every dependency. Call once before `runApp`.
/// Tests call `await getIt.reset()` and then this again.
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<GoRouter>(createRouter);
}
