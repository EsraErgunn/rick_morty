import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/dio_client.dart';
import '../core/storage/api_data_store.dart';
import '../core/storage/hive_init.dart';
import '../core/storage/player_store.dart';
import '../features/sync/data/remote_data_source.dart';
import '../features/sync/data/sync_repository_impl.dart';
import '../features/sync/domain/sync_repository.dart';
import 'router.dart';

/// The app's service locator. Only `main` and composition code (router)
/// read from it; widgets and blocs get their dependencies passed in.
final GetIt getIt = GetIt.instance;

/// Registers every dependency. Call once before `runApp`.
/// [storageDirectory] overrides the Hive directory (tests); the app uses
/// `getApplicationSupportDirectory()`.
/// Tests call `await getIt.reset()` and then this again.
Future<void> configureDependencies({String? storageDirectory}) async {
  initHive(storageDirectory ?? (await getApplicationSupportDirectory()).path);

  final apiData = await ApiDataStore.open();
  final player = await PlayerStore.open();
  final collection = await CollectionStore.open();

  getIt
    ..registerLazySingleton<ApiClient>(ApiClient.new, dispose: (c) => c.close())
    ..registerSingleton<ApiDataStore>(apiData)
    ..registerSingleton<PlayerStore>(player)
    ..registerSingleton<CollectionStore>(collection)
    ..registerLazySingleton<SyncRemoteDataSource>(
      () => ApiSyncRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<SyncRepository>(
      () =>
          SyncRepositoryImpl(remote: getIt(), store: getIt(), player: getIt()),
    )
    ..registerLazySingleton<GoRouter>(
      () => createRouter(syncRepository: getIt()),
    );
}
