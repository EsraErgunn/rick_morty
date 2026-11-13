import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

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
      // A failed write only means the intro shows again next launch; the
      // player still goes on to the menu.
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
