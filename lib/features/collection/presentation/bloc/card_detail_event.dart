import 'package:equatable/equatable.dart';

sealed class CardDetailEvent extends Equatable {
  const CardDetailEvent();

  @override
  List<Object?> get props => [];
}

final class CardDetailStarted extends CardDetailEvent {
  const CardDetailStarted();
}

/// "Desteye ekle" / "Desteden çıkar".
final class CardDeckToggled extends CardDetailEvent {
  const CardDeckToggled();
}
