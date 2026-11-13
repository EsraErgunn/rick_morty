import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// İlk açılış tanıtımının akışı: vitrin kartları, sayfa ve bitirme.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._repository) : super(const OnboardingState()) {
    on<OnboardingStarted>(
      (event, emit) => emit(state.copyWith(cards: _repository.showcaseCards())),
    );
    on<OnboardingPageChanged>(
      (event, emit) => emit(
        state.copyWith(
          page: event.page.clamp(0, OnboardingState.pageCount - 1),
        ),
      ),
    );
    on<OnboardingFinished>((event, emit) async {
      if (state.status == OnboardingStatus.loading ||
          state.status == OnboardingStatus.success) {
        return;
      }
      emit(state.copyWith(status: OnboardingStatus.loading));
      // Başarısız bir yazım yalnızca tanıtımın sonraki açılışta yeniden çıkacağı anlamına gelir;
      // oyuncu yine de menüye geçer.
      final result = await _repository.markSeen();
      emit(
        state.copyWith(
          status: result.isRight()
              ? OnboardingStatus.success
              : OnboardingStatus.failure,
        ),
      );
    });
  }

  final OnboardingRepository _repository;
}
