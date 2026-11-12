import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/cards/game_card_data.dart';
import '../core/widgets/shader_cache.dart';
import '../features/sync/domain/sync_repository.dart';
import '../features/sync/presentation/bloc/sync_bloc.dart';
import '../features/sync/presentation/bloc/sync_event.dart';
import '../features/sync/presentation/pages/splash_page.dart';
import '../l10n/app_localizations.dart';
import 'debug/card_lab_page.dart';
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

  /// Debug builds only (plan T17).
  static const String cardLab = '/debug/card-lab';

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

/// Routes from SPEC §2. Features not built yet point at a placeholder.
GoRouter createRouter({
  required SyncRepository syncRepository,
  List<GameCardData> Function()? cardLabCards,
  WidgetBuilder? collectionPage,
  Widget Function(BuildContext context, int id)? cardDetailPage,
  WidgetBuilder? portalPage,
  ShaderCache? shaders,
  WidgetBuilder? menuPage,
  WidgetBuilder? settingsPage,
  WidgetBuilder? deckPage,
  WidgetBuilder? battlePage,
  bool debugRoutes = kDebugMode,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => BlocProvider(
          create: (_) => SyncBloc(syncRepository)..add(const SyncStarted()),
          child: SplashPage(
            onDone: () => context.go(AppRoutes.menu),
            shaders: shaders,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.menu,
        builder: (context, state) {
          if (menuPage != null) return menuPage(context);
          final l10n = AppLocalizations.of(context);
          return PlaceholderPage(
            title: l10n.menuTitle,
            action: debugRoutes
                ? OutlinedButton(
                    onPressed: () => context.go(AppRoutes.cardLab),
                    child: Text(l10n.cardLabTitle),
                  )
                : null,
          );
        },
      ),
      if (portalPage != null)
        GoRoute(
          path: AppRoutes.portal,
          builder: (context, _) => portalPage(context),
        )
      else
        _placeholder(AppRoutes.portal, (l10n, _) => l10n.portalTitle),
      GoRoute(
        path: AppRoutes.collection,
        builder: (context, state) =>
            collectionPage?.call(context) ??
            PlaceholderPage(
              title: AppLocalizations.of(context).collectionTitle,
            ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final raw = state.pathParameters['id']!;
              final id = int.tryParse(raw);
              if (id == null || cardDetailPage == null) {
                return PlaceholderPage(
                  title: AppLocalizations.of(context).cardDetailTitle(raw),
                );
              }
              return cardDetailPage(context, id);
            },
          ),
        ],
      ),
      if (deckPage != null)
        GoRoute(
          path: AppRoutes.deck,
          builder: (context, _) => deckPage(context),
        )
      else
        _placeholder(AppRoutes.deck, (l10n, _) => l10n.deckTitle),
      if (battlePage != null)
        GoRoute(
          path: AppRoutes.battle,
          builder: (context, _) => battlePage(context),
        )
      else
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
      if (settingsPage != null)
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, _) => settingsPage(context),
        )
      else
        _placeholder(AppRoutes.settings, (l10n, _) => l10n.settingsTitle),
      if (debugRoutes)
        GoRoute(
          path: AppRoutes.cardLab,
          builder: (context, state) => CardLabPage(
            cards: cardLabCards?.call() ?? const [],
            onOpen: (id) => context.push(AppRoutes.cardDetail(id)),
          ),
        ),
    ],
  );
}
