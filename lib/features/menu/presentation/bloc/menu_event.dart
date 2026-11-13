import 'package:equatable/equatable.dart';

sealed class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

/// Menu shown (or shown again after another screen).
final class MenuStarted extends MenuEvent {
  const MenuStarted();
}

/// Stored data changed (coins, cards, deck), on this or any other screen.
final class MenuDataChanged extends MenuEvent {
  const MenuDataChanged();
}
