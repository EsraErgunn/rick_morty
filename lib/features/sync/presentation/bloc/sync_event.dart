import 'package:equatable/equatable.dart';

sealed class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Splash opened: download what is missing (or skip if synced).
final class SyncStarted extends SyncEvent {
  const SyncStarted();
}

/// "Tekrar dene" tapped after a failure: resume from the last saved page.
final class SyncRetryRequested extends SyncEvent {
  const SyncRetryRequested();
}
