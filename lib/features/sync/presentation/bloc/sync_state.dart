import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/sync_repository.dart';

/// Senkronun durumu.
enum SyncStatus { initial, loading, success, failure }

/// Splash ekranının durumu: senkron durumu, ilerleme ve hata.
final class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.initial,
    this.progress = const SyncProgress(downloaded: 0, total: 0),
    this.failure,
  });

  final SyncStatus status;
  final SyncProgress progress;

  /// Yalnızca [SyncStatus.failure] durumunda dolu.
  final Failure? failure;

  /// Ağ türü hatalar "Bağlantı koptu..." gösterir (SPEC §2.1 AC3).
  bool get isConnectionProblem => switch (failure) {
    NetworkFailure() || TimeoutFailure() || ServerFailure() => true,
    _ => false,
  };

  SyncState copyWith({SyncStatus? status, SyncProgress? progress}) => SyncState(
    status: status ?? this.status,
    progress: progress ?? this.progress,
    failure: failure,
  );

  SyncState failed(Failure failure) => SyncState(
    status: SyncStatus.failure,
    progress: progress,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, progress, failure];
}
