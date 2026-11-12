import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:portalcards/core/errors/failures.dart';
import 'package:portalcards/features/sync/domain/sync_repository.dart';
import 'package:portalcards/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:portalcards/features/sync/presentation/bloc/sync_event.dart';
import 'package:portalcards/features/sync/presentation/bloc/sync_state.dart';

import 'fake_sync_repository.dart';

const _p1 = SyncProgress(downloaded: 20, total: 100);
const _p2 = SyncProgress(downloaded: 100, total: 100);

void main() {
  test('initial state is initial with zero progress', () {
    expect(SyncBloc(FakeSyncRepository()).state, const SyncState());
  });

  blocTest<SyncBloc, SyncState>(
    'SyncStarted: loading, progress updates, success',
    build: () => SyncBloc(FakeSyncRepository(progress: [_p1, _p2])),
    act: (bloc) => bloc.add(const SyncStarted()),
    expect: () => const [
      SyncState(status: SyncStatus.loading),
      SyncState(status: SyncStatus.loading, progress: _p1),
      SyncState(status: SyncStatus.loading, progress: _p2),
      SyncState(status: SyncStatus.success, progress: _p2),
    ],
  );

  blocTest<SyncBloc, SyncState>(
    'SyncStarted: a network failure keeps the progress reached so far',
    build: () => SyncBloc(
      FakeSyncRepository(
        progress: [_p1],
        results: [left(const NetworkFailure())],
      ),
    ),
    act: (bloc) => bloc.add(const SyncStarted()),
    expect: () => const [
      SyncState(status: SyncStatus.loading),
      SyncState(status: SyncStatus.loading, progress: _p1),
      SyncState(
        status: SyncStatus.failure,
        progress: _p1,
        failure: NetworkFailure(),
      ),
    ],
    verify: (bloc) => expect(bloc.state.isConnectionProblem, isTrue),
  );

  blocTest<SyncBloc, SyncState>(
    'SyncRetryRequested after a failure resumes and succeeds',
    build: () => SyncBloc(
      FakeSyncRepository(
        progress: [_p1],
        results: [left(const TimeoutFailure()), right(unit)],
      ),
    ),
    seed: () => const SyncState(
      status: SyncStatus.failure,
      progress: _p1,
      failure: TimeoutFailure(),
    ),
    act: (bloc) async {
      bloc.add(const SyncRetryRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SyncRetryRequested());
    },
    expect: () => const [
      SyncState(status: SyncStatus.loading, progress: _p1),
      SyncState(
        status: SyncStatus.failure,
        progress: _p1,
        failure: TimeoutFailure(),
      ),
      SyncState(status: SyncStatus.loading, progress: _p1),
      SyncState(status: SyncStatus.success, progress: _p1),
    ],
  );

  blocTest<SyncBloc, SyncState>(
    'a storage failure is not shown as a connection problem',
    build: () =>
        SyncBloc(FakeSyncRepository(results: [left(const StorageFailure())])),
    act: (bloc) => bloc.add(const SyncStarted()),
    skip: 1,
    expect: () => const [
      SyncState(status: SyncStatus.failure, failure: StorageFailure()),
    ],
    verify: (bloc) => expect(bloc.state.isConnectionProblem, isFalse),
  );

  test(
    'a second start while loading is ignored (one sync at a time)',
    () async {
      final repo = FakeSyncRepository(hold: true);
      final bloc = SyncBloc(repo)
        ..add(const SyncStarted())
        ..add(const SyncRetryRequested());
      await Future<void>.delayed(Duration.zero);
      repo.release();
      await bloc.stream.firstWhere((s) => s.status == SyncStatus.success);

      expect(repo.runs, 1);
      await bloc.close();
    },
  );
}
