import 'dart:async';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../core/audio/audio_backend.dart';
import '../core/audio/audio_service.dart';
import '../core/cards/card_factory.dart';
import '../core/feedback/ui_feedback.dart';
import '../core/haptics/haptics_service.dart';
import '../core/images/image_download_controller.dart';
import '../core/cards/rarity_pool.dart';
import '../core/network/dio_client.dart';
import '../core/sensors/shake_detector.dart';
import '../core/sensors/tilt_stream.dart';
import '../core/storage/api_data_store.dart';
import '../core/storage/hive_init.dart';
import '../core/storage/player_store.dart';
import '../core/widgets/shader_cache.dart';
import '../features/album/data/album_repository_impl.dart';
import '../features/album/domain/album_repository.dart';
import '../features/album/presentation/bloc/album_bloc.dart';
import '../features/album/presentation/bloc/album_event.dart';
import '../features/album/presentation/pages/album_episode_page.dart';
import '../features/album/presentation/pages/album_page.dart';
import '../features/collection/data/collection_repository_impl.dart';
import '../features/collection/domain/collection_repository.dart';
import '../features/collection/presentation/bloc/card_detail_bloc.dart';
import '../features/collection/presentation/bloc/card_detail_event.dart';
import '../features/collection/presentation/bloc/collection_bloc.dart';
import '../features/collection/presentation/bloc/collection_event.dart';
import '../features/collection/presentation/pages/card_detail_page.dart';
import '../features/collection/presentation/pages/collection_page.dart';
import '../features/battle/data/battle_repository_impl.dart';
import '../features/battle/domain/battle_repository.dart';
import '../features/battle/presentation/battle_feedback.dart';
import '../features/battle/presentation/bloc/battle_bloc.dart';
import '../features/battle/presentation/bloc/battle_event.dart';
import '../features/battle/presentation/pages/battle_page.dart';
import '../features/deck/presentation/bloc/deck_bloc.dart';
import '../features/deck/presentation/bloc/deck_event.dart';
import '../features/deck/presentation/pages/deck_page.dart';
import '../features/menu/data/menu_repository_impl.dart';
import '../features/menu/presentation/bloc/menu_bloc.dart';
import '../features/menu/presentation/bloc/menu_event.dart';
import '../features/menu/presentation/pages/menu_page.dart';
import '../features/portal/data/portal_repository_impl.dart';
import '../features/portal/domain/portal_repository.dart';
import '../features/portal/presentation/bloc/portal_bloc.dart';
import '../features/portal/presentation/bloc/portal_event.dart';
import '../features/portal/presentation/pages/portal_page.dart';
import '../features/portal/presentation/portal_feedback.dart';
import '../features/settings/data/settings_repository_impl.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/settings/presentation/bloc/settings_event.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/widgets/image_download_tile.dart';
import '../features/sync/data/remote_data_source.dart';
import '../features/sync/data/sync_repository_impl.dart';
import '../features/sync/domain/sync_repository.dart';
import 'app_info.dart';
import 'debug/card_lab_page.dart';
import 'router.dart';

/// The app's service locator. Only `main` and composition code (router)
/// read from it; widgets and blocs get their dependencies passed in.
final GetIt getIt = GetIt.instance;

/// Registers every dependency. Call once before `runApp`.
/// [storageDirectory] overrides the Hive directory (tests); the app uses
/// `getApplicationSupportDirectory()`.
/// Tests call `await getIt.reset()` and then this again.
Future<void> configureDependencies({
  String? storageDirectory,
  String initialLocation = AppRoutes.splash,
}) async {
  initHive(storageDirectory ?? (await getApplicationSupportDirectory()).path);

  final apiData = await ApiDataStore.open();
  final player = await PlayerStore.open();
  final collection = await CollectionStore.open();
  // Shaders load once per run, before any card needs them.
  final shaders = ShaderCache(
    enabled: !shadersDisabled(isRelease: kReleaseMode),
  );
  await shaders.load();

  getIt
    ..registerLazySingleton<ApiClient>(ApiClient.new, dispose: (c) => c.close())
    ..registerSingleton<ApiDataStore>(apiData)
    ..registerSingleton<PlayerStore>(player)
    ..registerSingleton<CollectionStore>(collection)
    ..registerSingleton<ShaderCache>(shaders)
    ..registerLazySingleton<SyncRemoteDataSource>(
      () => ApiSyncRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<SyncRepository>(
      () =>
          SyncRepositoryImpl(remote: getIt(), store: getIt(), player: getIt()),
    )
    // Built on first use, which is after the splash finished the sync
    // (portal, Week 2). A later re-sync must reset it (SPEC §3).
    ..registerLazySingleton<RarityPool>(
      () => RarityPool.fromCharacters(getIt<ApiDataStore>().characters),
    )
    // All sound goes through AudioService (rules); preloaded in main().
    ..registerLazySingleton<AudioService>(
      () => AudioService(
        backend: AudioplayersBackend(),
        settings: player.state.settings,
      ),
      dispose: (a) => a.detachLifecycle(),
    )
    // All vibration goes through HapticsService (rules).
    ..registerLazySingleton<HapticsService>(
      () => HapticsService(settings: player.state.settings),
    )
    // Shake to open the portal; active only while the portal page listens.
    ..registerLazySingleton<ShakeDetector>(
      ShakeDetector.new,
      dispose: (d) => d.dispose(),
    )
    // Image disk-cache downloads (SPEC §3 Images); survives page changes.
    ..registerLazySingleton<ImageDownloadController>(
      ImageDownloadController.new,
      dispose: (c) => c.dispose(),
    )
    // The only tilt sensor subscription in the app (sensors rules).
    ..registerLazySingleton<TiltStream>(
      TiltStream.new,
      dispose: (t) => t.dispose(),
    )
    // The app's only unseeded Random is created here, in composition code;
    // game logic always receives it (architecture rules).
    ..registerLazySingleton<BattleRepository>(
      () => BattleRepositoryImpl(
        apiData: getIt(),
        player: getIt(),
        pool: getIt(),
      ),
    )
    ..registerLazySingleton<CollectionRepository>(
      () => CollectionRepositoryImpl(
        apiData: getIt(),
        player: getIt(),
        collection: getIt(),
      ),
    )
    ..registerLazySingleton<PortalRepository>(
      () => PortalRepositoryImpl(
        apiData: getIt(),
        player: getIt(),
        collection: getIt(),
        pool: getIt(),
        random: Random(),
      ),
    )
    ..registerLazySingleton<AlbumRepository>(
      () => AlbumRepositoryImpl(
        apiData: getIt(),
        player: getIt(),
        collection: getIt(),
      ),
    )
    ..registerLazySingleton<GoRouter>(
      () => createRouter(
        syncRepository: getIt(),
        initialLocation: initialLocation,
        shaders: getIt(),
        menuPage: (context) => BlocProvider(
          create: (_) => MenuBloc(
            MenuRepositoryImpl(
              apiData: getIt(),
              player: getIt(),
              collection: getIt(),
            ),
          )..add(const MenuStarted()),
          child: MenuPage(
            shaders: getIt(),
            audio: getIt(),
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
            // Owned cards + deck art into the disk cache, in the background.
            onShown: () {
              final cards = getIt<CollectionRepository>();
              unawaited(
                getIt<ImageDownloadController>().warmUp([
                  for (final e in cards.entries()) e.card.imageUrl,
                  for (final id in cards.deck)
                    if (cards.card(id) case final c?) c.imageUrl,
                ]),
              );
            },
            actions: MenuActions(
              portal: () => context.go(AppRoutes.portal),
              collection: () => context.go(AppRoutes.collection),
              deck: () => context.go(AppRoutes.deck),
              battle: () => context.go(AppRoutes.battle),
              album: () => context.go(AppRoutes.album),
              settings: () => context.go(AppRoutes.settings),
              debugCardLab: kDebugMode
                  ? () => context.go(AppRoutes.cardLab)
                  : null,
            ),
          ),
        ),
        battlePage: (context) => BlocProvider(
          create: (_) => BattleBloc(
            repository: getIt(),
            random: Random(),
            newBattleId: () => DateTime.now().microsecondsSinceEpoch.toString(),
          )..add(const BattleOpened()),
          child: BattlePage(
            feedback: BattleFeedback(audio: getIt(), haptics: getIt()),
            onExit: () => context.go(AppRoutes.menu),
            onGoToDeck: () => context.go(AppRoutes.deck),
          ),
        ),
        deckPage: (context) => BlocProvider(
          create: (_) => DeckBloc(getIt())..add(const DeckStarted()),
          child: DeckPage(
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
          ),
        ),
        settingsPage: (context) => BlocProvider(
          create: (_) => SettingsBloc(
            SettingsRepositoryImpl(player: getIt(), collection: getIt()),
          )..add(const SettingsStarted()),
          child: SettingsPage(
            audio: getIt(),
            haptics: getIt(),
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
            version: AppInfo.version,
            extra: ImageDownloadTile(
              controller: getIt(),
              urls: () => [
                for (final c in getIt<ApiDataStore>().characters) c.imageUrl,
              ],
              feedback: UiFeedback(audio: getIt(), haptics: getIt()),
            ),
          ),
        ),
        portalPage: (context) => BlocProvider(
          create: (_) => PortalBloc(getIt())..add(const PortalStarted()),
          child: PortalPage(
            shaders: getIt(),
            shake: getIt(),
            feedback: PortalFeedback(audio: getIt(), haptics: getIt()),
            deckReady: getIt<PlayerStore>().state.deck.length == 3,
            onGoToBattle: () => context.go(AppRoutes.battle),
            onGoToCollection: () => context.go(AppRoutes.collection),
          ),
        ),
        collectionPage: (context) => BlocProvider(
          create: (_) =>
              CollectionBloc(getIt())..add(const CollectionStarted()),
          child: CollectionPage(
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
            onOpenCard: (id) => context.push(AppRoutes.cardDetail(id)),
            onOpenPortal: () => context.go(AppRoutes.portal),
          ),
        ),
        cardDetailPage: (context, id) => BlocProvider(
          create: (_) =>
              CardDetailBloc(getIt(), id)..add(const CardDetailStarted()),
          child: CardDetailPage(
            id: id,
            tiltStream: getIt(),
            shaders: getIt(),
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
          ),
        ),
        albumPage: (context) => BlocProvider(
          create: (_) => AlbumBloc(getIt())..add(const AlbumStarted()),
          child: AlbumPage(
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
            onOpen: (id) => context.push(AppRoutes.albumPage(id)),
          ),
        ),
        albumEpisodePage: (context, id) => BlocProvider(
          create: (_) =>
              AlbumPageBloc(getIt(), id)..add(const AlbumPageStarted()),
          child: AlbumEpisodePage(
            feedback: UiFeedback(audio: getIt(), haptics: getIt()),
          ),
        ),
        cardLabCards: () => [
          for (final id in CardLabPage.characterIds)
            if (getIt<ApiDataStore>().character(id) case final c?)
              CardFactory.fromCharacter(c),
        ],
      ),
    );
}
