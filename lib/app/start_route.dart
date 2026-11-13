import 'router.dart';

/// `--dart-define=START_ROUTE=/collection/1` (performans ölçümleri, `docs/perf/`).
const String startRouteDefine = String.fromEnvironment('START_ROUTE');

/// Uygulamanın ilk rotası. İstenen [requested] rota yalnızca debug ve
/// profile derlemelerde ve yalnızca mutlak bir yolsa dikkate alınır; release
/// derlemeler her zaman splash'ten başlar.
String resolveStartRoute({
  required bool isRelease,
  String requested = startRouteDefine,
}) {
  if (isRelease) return AppRoutes.splash;
  final route = requested.trim();
  if (route.isEmpty || !route.startsWith('/')) return AppRoutes.splash;
  return route;
}
