import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../collection/domain/collection_repository.dart';
import 'deck_event.dart';
import 'deck_state.dart';

/// Deck builder (SPEC §2.6): fill the first empty slot, empty a slot, no
/// duplicates, saved at once. Uses the collection's deck storage.
class DeckBloc extends Bloc<DeckEvent, DeckState> {
  DeckBloc(this._repository) : super(const DeckState()) {
    on<DeckStarted>(_load);
    on<DeckDataChanged>(_load);
    _changes = _repository.changes.listen((_) => add(const DeckDataChanged()));
    on<DeckCardTapped>((e, emit) async {
      if (state.deck.contains(e.id) || state.complete) return;
      final r = await _repository.toggleDeck(e.id);
      r.match((_) {}, (deck) {
        final done = deck.length == DeckState.size;
        emit(
          state.copyWith(
            deck: deck,
            change: done ? DeckChange.completed : DeckChange.added,
            changeTick: state.changeTick + 1,
          ),
        );
      });
    });
    on<DeckSlotTapped>((e, emit) async {
      if (e.index >= state.deck.length) return;
      final r = await _repository.toggleDeck(state.deck[e.index]);
      r.match(
        (_) {},
        (deck) => emit(
          state.copyWith(
            deck: deck,
            change: DeckChange.removed,
            changeTick: state.changeTick + 1,
          ),
        ),
      );
    });
  }

  final CollectionRepository _repository;
  late final StreamSubscription<void> _changes;

  void _load(DeckEvent e, Emitter<DeckState> emit) => emit(
    state.copyWith(
      status: DeckStatus.success,
      owned: [for (final entry in _repository.entries()) entry.card],
      deck: _repository.deck,
    ),
  );

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
