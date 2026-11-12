import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'not_found_page.dart';
import 'placeholder_page.dart';

/// Route paths from SPEC §2. Build links with these, never with raw strings.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String menu = '/';
  static const String portal = '/portal';
  static const String collection = '/collection';
  static const String deck = '/deck';
  static const String battle = '/battle';
  static const String album = '/album';
  static const String settings = '/settings';

  static String cardDetail(int id) => '$collection/$id';
  static String albumPage(int episodeId) => '$album/$episodeId';
}

typedef _TitleOf = String Function(AppLocalizations l10n, GoRouterState state);

GoRoute _placeholder(
  String path,
  _TitleOf title, {
  List<RouteBase> routes = const [],
}) => GoRoute(
  path: path,
  routes: routes,
  builder: (context, state) =>
      PlaceholderPage(title: title(AppLocalizations.of(context), state)),
);

/// Every route points at a placeholder until its feature task replaces it.
GoRouter createRouter({String initialLocation = AppRoutes.splash}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      _placeholder(AppRoutes.splash, (l10n, _) => l10n.splashTitle),
      _placeholder(AppRoutes.menu, (l10n, _) => l10n.menuTitle),
      _placeholder(AppRoutes.portal, (l10n, _) => l10n.portalTitle),
      _placeholder(
        AppRoutes.collection,
        (l10n, _) => l10n.collectionTitle,
        routes: [
          _placeholder(
            ':id',
            (l10n, state) => l10n.cardDetailTitle(state.pathParameters['id']!),
          ),
        ],
      ),
      _placeholder(AppRoutes.deck, (l10n, _) => l10n.deckTitle),
      _placeholder(AppRoutes.battle, (l10n, _) => l10n.battleTitle),
      _placeholder(
        AppRoutes.album,
        (l10n, _) => l10n.albumTitle,
        routes: [
          _placeholder(
            ':episodeId',
            (l10n, state) =>
                l10n.albumPageTitle(state.pathParameters['episodeId']!),
          ),
        ],
      ),
      _placeholder(AppRoutes.settings, (l10n, _) => l10n.settingsTitle),
    ],
  );
}
