import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// The intro opened: load the showcase cards.
final class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

/// The user swiped (or tapped a dot) to [page].
final class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

/// "Geç" or "Başla": remember the intro and leave.
final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}
