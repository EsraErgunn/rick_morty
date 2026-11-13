import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// Splash'i yönetir: `initial → loading(progress) → success | failure`.
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this._repository) : super(const SyncState()) {
    on<SyncStarted>(_run);
    on<SyncRetryRequested>(_run);
  }

  final SyncRepository _repository;

  Future<void> _run(SyncEvent event, Emitter<SyncState> emit) async {
    // Aynı anda tek senkron; çalışırken ikinci bir dokunuş ya da olay yok sayılır.
    if (state.status == SyncStatus.loading) return;
    emit(SyncState(status: SyncStatus.loading, progress: state.progress));

    final result = await _repository.sync(
      onProgress: (progress) {
        if (!emit.isDone) emit(state.copyWith(progress: progress));
      },
    );

    result.match(
      (failure) => emit(state.failed(failure)),
      (_) => emit(state.copyWith(status: SyncStatus.success)),
    );
  }
}
