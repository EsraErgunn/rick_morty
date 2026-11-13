import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/collection_repository.dart';
import 'collection_event.dart';
import 'collection_state.dart';

/// Collection grid (SPEC §2.4): owned cards, filters, sort.
class CollectionBloc extends Bloc<CollectionEvent, CollectionState> {
  CollectionBloc(this._repository) : super(const CollectionState()) {
    on<CollectionStarted>(_load);
    on<CollectionDataChanged>(_load);
    _changes = _repository.changes.listen(
      (_) => add(const CollectionDataChanged()),
    );
    on<CollectionRarityToggled>(
      (event, emit) =>
          emit(state.copyWith(rarities: _toggle(state.rarities, event.rarity))),
    );
    on<CollectionTypeToggled>(
      (event, emit) =>
          emit(state.copyWith(types: _toggle(state.types, event.type))),
    );
    on<CollectionFiltersCleared>(
      (event, emit) => emit(state.copyWith(rarities: {}, types: {})),
    );
    on<CollectionSortChanged>(
      (event, emit) => emit(state.copyWith(sort: event.sort)),
    );
  }

  final CollectionRepository _repository;
  late final StreamSubscription<void> _changes;

  /// Filters and sort are kept; only the data is reloaded.
  void _load(CollectionEvent event, Emitter<CollectionState> emit) => emit(
    state.copyWith(
      status: CollectionStatus.success,
      entries: _repository.entries(),
      total: _repository.totalCharacters,
    ),
  );

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}
