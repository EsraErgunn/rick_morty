import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/collection_repository.dart';
import 'card_detail_event.dart';
import 'card_detail_state.dart';

/// Kart detayı (SPEC §2.5): kart, sahiplik ve deste işlemi.
class CardDetailBloc extends Bloc<CardDetailEvent, CardDetailState> {
  CardDetailBloc(this._repository, this._id) : super(const CardDetailState()) {
    on<CardDetailStarted>((event, emit) {
      final card = _repository.card(_id);
      emit(
        CardDetailState(
          status: card == null
              ? CardDetailStatus.notFound
              : CardDetailStatus.success,
          card: card,
          owned: _repository.owns(_id),
          deck: _repository.deck,
        ),
      );
    });
    on<CardDeckToggled>((event, emit) async {
      final result = await _repository.toggleDeck(_id);
      emit(
        result.match(
          (f) => CardDetailState(
            status: state.status,
            card: state.card,
            owned: state.owned,
            deck: state.deck,
            failure: f,
          ),
          (deck) => CardDetailState(
            status: state.status,
            card: state.card,
            owned: state.owned,
            deck: deck,
          ),
        ),
      );
    });
  }

  final CollectionRepository _repository;
  final int _id;
}
