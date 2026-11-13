import 'package:equatable/equatable.dart';

sealed class DeckEvent extends Equatable {
  const DeckEvent();

  @override
  List<Object?> get props => [];
}

final class DeckStarted extends DeckEvent {
  const DeckStarted();
}

/// Stored cards or deck changed (here or on another screen).
final class DeckDataChanged extends DeckEvent {
  const DeckDataChanged();
}

/// An owned card tapped: it goes into the first empty slot.
final class DeckCardTapped extends DeckEvent {
  const DeckCardTapped(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

/// A filled slot tapped: it empties.
final class DeckSlotTapped extends DeckEvent {
  const DeckSlotTapped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}
