import 'package:equatable/equatable.dart';

sealed class AlbumEvent extends Equatable {
  const AlbumEvent();

  @override
  List<Object?> get props => [];
}

/// Album list opened.
final class AlbumStarted extends AlbumEvent {
  const AlbumStarted();
}

/// Cards or coins changed (a portal, a reward): reload and pay new pages.
final class AlbumDataChanged extends AlbumEvent {
  const AlbumDataChanged();
}

/// One episode page opened.
final class AlbumPageStarted extends AlbumEvent {
  const AlbumPageStarted();
}
