import 'package:equatable/equatable.dart';

import '../../../../core/cards/game_card_data.dart';

enum OnboardingStatus { initial, loading, success, failure }

/// [status] success = the intro is finished and the page may leave.
final class OnboardingState extends Equatable {
  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.page = 0,
    this.cards = const [],
  });

  static const int pageCount = 4;

  final OnboardingStatus status;
  final int page;

  /// Common → legendary showcase cards (may be empty).
  final List<GameCardData> cards;

  bool get isLast => page == pageCount - 1;

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? page,
    List<GameCardData>? cards,
  }) => OnboardingState(
    status: status ?? this.status,
    page: page ?? this.page,
    cards: cards ?? this.cards,
  );

  @override
  List<Object?> get props => [status, page, cards];
}
