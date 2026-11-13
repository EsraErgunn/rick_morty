import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/album_repository.dart';
import 'album_event.dart';
import 'album_state.dart';

/// Episode album list [GM §9]. Reloads on every stored change (a portal
/// card shows up at once) and pays each completed page once.
class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  AlbumBloc(this._repository) : super(const AlbumState()) {
    on<AlbumStarted>(_load);
    on<AlbumDataChanged>(_load);
    _changes = _repository.changes.listen((_) => add(const AlbumDataChanged()));
  }

  final AlbumRepository _repository;
  late final StreamSubscription<void> _changes;

  Future<void> _load(AlbumEvent e, Emitter<AlbumState> emit) async {
    emit(
      state.copyWith(
        status: AlbumStatus.success,
        episodes: _repository.episodes(),
      ),
    );
    final paid = await _repository.claimCompleted();
    if (paid.isEmpty) return;
    emit(state.copyWith(rewards: paid, rewardTick: state.rewardTick + 1));
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

/// One episode page; reloads on every stored change.
class AlbumPageBloc extends Bloc<AlbumEvent, AlbumPageState> {
  AlbumPageBloc(this._repository, this._episodeId)
    : super(const AlbumPageState()) {
    on<AlbumPageStarted>(_load);
    on<AlbumDataChanged>(_load);
    _changes = _repository.changes.listen((_) => add(const AlbumDataChanged()));
  }

  final AlbumRepository _repository;
  final int _episodeId;
  late final StreamSubscription<void> _changes;

  void _load(AlbumEvent e, Emitter<AlbumPageState> emit) => emit(
    AlbumPageState(
      status: AlbumStatus.success,
      episode: _repository.episode(_episodeId),
      members: _repository.members(_episodeId),
    ),
  );

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
