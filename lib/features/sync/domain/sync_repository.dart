import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failures.dart';

/// Items downloaded so far across characters, episodes and locations.
final class SyncProgress extends Equatable {
  const SyncProgress({required this.downloaded, required this.total});

  final int downloaded;

  /// Sum of `info.count` of the three resources (0 until known).
  final int total;

  /// 0.0 to 1.0.
  double get fraction => total == 0 ? 0 : (downloaded / total).clamp(0, 1);

  /// Whole percent, 0 to 100.
  int get percent => (fraction * 100).floor();

  @override
  List<Object?> get props => [downloaded, total];
}

/// First-launch download of the API into local storage (SPEC §2.1).
abstract interface class SyncRepository {
  /// True once a full sync completed; later launches skip the network.
  bool get isSynced;

  /// Downloads what is missing, page by page, resuming after the last
  /// completed page. Reports progress after each saved page. A failure keeps
  /// everything saved so far.
  Future<Either<Failure, Unit>> sync({
    required void Function(SyncProgress progress) onProgress,
  });
}
