import 'package:equatable/equatable.dart';

sealed class PortalEvent extends Equatable {
  const PortalEvent();

  @override
  List<Object?> get props => [];
}

/// Page opened: load coins and the hint flag.
final class PortalStarted extends PortalEvent {
  const PortalStarted();
}

/// The phone was shaken (ShakeDetector).
final class PortalShaken extends PortalEvent {
  const PortalShaken();
}

/// "Portalı aç" tapped (fallback for emulators and accessibility).
final class PortalOpenRequested extends PortalEvent {
  const PortalOpenRequested();
}

/// The reveal scene finished (card flipped, effects done).
final class RevealFinished extends PortalEvent {
  const RevealFinished();
}

/// "Tekrar aç" / leaving the result: back to the idle portal.
final class PortalReset extends PortalEvent {
  const PortalReset();
}
