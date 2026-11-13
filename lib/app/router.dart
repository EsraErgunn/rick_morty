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

  /// First-launch intro (shown once, replayable from Settings).
  static const String onboarding = '/onboarding';
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
  WidgetBuilder? albumPage,
  WidgetBuilder? onboardingPage,
  bool Function()? onboardingSeen,
  Widget Function(BuildContext context, int episodeId)? albumEpisodePage,
  bool debugRoutes = kDebugMode,
  String initialLocation = AppRoutes.splash,
}) {
  // Screens are children of the menu, so `go('/portal')` builds the stack
  // menu → portal: the back button and Android's back key return to the
  // right parent (card detail → collection → menu).
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => BlocProvider(
          create: (_) => SyncBloc(syncRepository)..add(const SyncStarted()),
          child: SplashPage(
            onDone: () => context.go(
              onboardingPage != null && !(onboardingSeen?.call() ?? true)
                  ? AppRoutes.onboarding
                  : AppRoutes.menu,
            ),
            shaders: shaders,
          ),
        ),
      ),
      if (onboardingPage != null)
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (context, state) => onboardingPage(context),
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
        routes: [
          _screen(AppRoutes.portal, portalPage, (l10n, _) => l10n.portalTitle),
          GoRoute(
            path: _child(AppRoutes.collection),
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
          _screen(AppRoutes.deck, deckPage, (l10n, _) => l10n.deckTitle),
          _screen(AppRoutes.battle, battlePage, (l10n, _) => l10n.battleTitle),
          GoRoute(
            path: _child(AppRoutes.album),
            builder: (context, state) =>
                albumPage?.call(context) ??
                PlaceholderPage(title: AppLocalizations.of(context).albumTitle),
            routes: [
              GoRoute(
                path: ':episodeId',
                builder: (context, state) {
                  final raw = state.pathParameters['episodeId']!;
                  final id = int.tryParse(raw);
                  if (id == null || albumEpisodePage == null) {
                    return PlaceholderPage(
                      title: AppLocalizations.of(context).albumPageTitle(raw),
                    );
                  }
                  return albumEpisodePage(context, id);
                },
              ),
            ],
          ),
          _screen(
            AppRoutes.settings,
            settingsPage,
            (l10n, _) => l10n.settingsTitle,
          ),
          if (debugRoutes)
            GoRoute(
              path: _child(AppRoutes.cardLab),
              builder: (context, state) => CardLabPage(
                cards: cardLabCards?.call() ?? const [],
                onOpen: (id) => context.push(AppRoutes.cardDetail(id)),
              ),
            ),
        ],
      ),
    ],
  );
}

/// '/portal' → 'portal' (a child of the menu route).
String _child(String path) => path.substring(1);

/// A menu child: the real page when built, otherwise a placeholder.
GoRoute _screen(String path, WidgetBuilder? page, _TitleOf title) =>
    page == null
    ? _placeholder(_child(path), title)
    : GoRoute(path: _child(path), builder: (context, _) => page(context));
