import 'router.dart';

/// `--dart-define=START_ROUTE=/collection/1` (perf runs, `docs/perf/`).
const String startRouteDefine = String.fromEnvironment('START_ROUTE');

/// The first route of the app. A [requested] route is honored only in
/// debug and profile builds and only if it is an absolute path; release
/// builds always start at the splash.
String resolveStartRoute({
  required bool isRelease,
  String requested = startRouteDefine,
}) {
  if (isRelease) return AppRoutes.splash;
  final route = requested.trim();
  if (route.isEmpty || !route.startsWith('/')) return AppRoutes.splash;
  return route;
}
