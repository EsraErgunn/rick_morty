import 'package:flutter_test/flutter_test.dart';
import 'package:portalcards/app/router.dart';
import 'package:portalcards/app/start_route.dart';

void main() {
  test('release builds ignore START_ROUTE and start at the splash', () {
    expect(
      resolveStartRoute(isRelease: true, requested: '/collection/1'),
      AppRoutes.splash,
    );
  });

  test('debug and profile builds honor START_ROUTE', () {
    expect(
      resolveStartRoute(isRelease: false, requested: '/collection/1'),
      '/collection/1',
    );
  });

  test('empty or relative values fall back to the splash', () {
    expect(
      resolveStartRoute(isRelease: false, requested: ''),
      AppRoutes.splash,
    );
    expect(
      resolveStartRoute(isRelease: false, requested: 'collection/1'),
      AppRoutes.splash,
    );
    expect(resolveStartRoute(isRelease: false, requested: '  /deck '), '/deck');
  });

  test('without a dart-define the start route is the splash', () {
    expect(startRouteDefine, isEmpty);
    expect(resolveStartRoute(isRelease: false), AppRoutes.splash);
  });
}
