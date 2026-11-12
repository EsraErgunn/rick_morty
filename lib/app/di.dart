import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../core/audio/audio_backend.dart';
import '../core/audio/audio_service.dart';
import '../core/cards/card_factory.dart';
import '../core/haptics/haptics_service.dart';
import '../core/cards/rarity_pool.dart';
import '../core/network/dio_client.dart';
import '../core/sensors/tilt_stream.dart';
import '../core/storage/api_data_store.dart';
import '../core/storage/hive_init.dart';
import '../core/storage/player_store.dart';
import '../core/widgets/game_card/shader_cache.dart';
import '../features/sync/data/remote_data_source.dart';
import '../features/sync/data/sync_repository_impl.dart';
import '../features/sync/domain/sync_repository.dart';
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
  final shaders = ShaderCache();
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
    // The only tilt sensor subscription in the app (sensors rules).
    ..registerLazySingleton<TiltStream>(
      TiltStream.new,
      dispose: (t) => t.dispose(),
    )
    ..registerLazySingleton<GoRouter>(
      () => createRouter(
        syncRepository: getIt(),
        initialLocation: initialLocation,
        tiltStream: getIt(),
        shaders: getIt(),
        cardById: (id) => switch (getIt<ApiDataStore>().character(id)) {
          final c? => CardFactory.fromCharacter(c),
          null => null,
        },
        cardLabCards: () => [
          for (final id in CardLabPage.characterIds)
            if (getIt<ApiDataStore>().character(id) case final c?)
              CardFactory.fromCharacter(c),
        ],
      ),
    );
}
